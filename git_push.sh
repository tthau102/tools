#!/bin/bash
set -e

# Default branch là branch hiện tại
branch=$(git rev-parse --abbrev-ref HEAD)

if [ -n "$1" ]; then
    branch="$1"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "$branch" ]; then
        echo "Switching to branch: $branch"
        git checkout "$branch" || { echo "Failed to checkout $branch"; exit 1; }
    fi
fi

# Check có thay đổi không
if ! git diff --cached --quiet; then
    : # Có staged changes, tiếp tục
else
    echo "No staged changes to commit"
    echo "Stage your changes with: git add <files>"
    echo ""
    git status --short
    exit 1
fi

# Lấy thông tin Git - ưu tiên upstream tracking branch
upstream_remote=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null | cut -d'/' -f1)
if [ -z "$upstream_remote" ]; then
    # Không có upstream, list all remotes để user chọn
    remote=""
else
    remote="$upstream_remote"
fi
changed_files=$(git diff --name-only --cached)
stats=$(git diff --cached --stat | tail -n 1)

# Parse số lượng files từ stats
if [[ $stats =~ ([0-9]+)\ file ]]; then
    file_count="${BASH_REMATCH[1]}"
    files_text="$file_count files"
else
    files_text="No files"
fi

# Kiểm tra AWS credentials và jq
use_ai=false
if command -v aws &>/dev/null && command -v jq &>/dev/null; then
    if aws sts get-caller-identity &>/dev/null; then
        use_ai=true
    fi
fi

# Tạo commit message
if [ "$use_ai" = true ]; then
    # Lấy diff content (giới hạn 15KB để tránh quá lớn)
    diff_content=$(git diff --cached | head -c 15000)
    
    prompt=$(cat <<EOF
Trả về chính xác một dòng commit message dựa trên các thay đổi sau đây. Không thêm bất kỳ giải thích hay nội dung phụ nào:

Các file đã thay đổi:
$changed_files

Chi tiết thay đổi:
$diff_content

Quy tắc:
- Chỉ trả về MỘT DÒNG duy nhất
- Bắt đầu bằng động từ hành động (Add, Update, Fix, Refactor, etc.)
- Ngắn gọn, không quá 72 ký tự
- Không thêm dấu ngoặc kép hoặc bất kỳ định dạng nào khác
- Không bao gồm chú thích hoặc giải thích
- Nếu code không có thay đổi, hãy trả về "No change"
EOF
)

    # Tạo file request tạm thời
    request_file=$(mktemp)
    response_file=$(mktemp)

    cat > "$request_file" << EOF
{
  "anthropic_version": "bedrock-2023-05-31",
  "max_tokens": 100,
  "messages": [
    {
      "role": "user",
      "content": $(echo "$prompt" | jq -Rs .)
    }
  ]
}
EOF

    # Gọi Bedrock API
    if aws bedrock-runtime invoke-model \
        --model-id apac.anthropic.claude-3-5-sonnet-20241022-v2:0 \
        --body file://$request_file \
        --cli-binary-format raw-in-base64-out \
        --region ap-southeast-1 \
        "$response_file" &>/dev/null; then
        
        commit_message=$(cat "$response_file" | jq -r '.content[0].text' 2>/dev/null)
        commit_message=$(echo "$commit_message" | tr -d '\n' | tr -d '\r')
        
        # Fallback nếu AI response không hợp lệ
        if [ -z "$commit_message" ] || [ "$commit_message" = "null" ]; then
            use_ai=false
        fi
    else
        use_ai=false
    fi

    # Xóa files tạm
    rm -f "$request_file" "$response_file"
fi

# Fallback: timestamp commit message
if [ "$use_ai" = false ]; then
    commit_message="[Auto] $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Xác định remote để push
available_remotes=($(git remote))
if [ ${#available_remotes[@]} -eq 0 ]; then
    echo "❌ No git remotes configured"
    exit 1
fi

# Nếu không có upstream hoặc upstream không tồn tại, cho phép chọn
if [ -z "$remote" ] || ! git remote | grep -q "^${remote}$"; then
    echo ""
    echo "Available remotes:"
    for i in "${!available_remotes[@]}"; do
        remote_url=$(git remote get-url "${available_remotes[$i]}" 2>/dev/null)
        echo "  [$((i+1))] ${available_remotes[$i]} → $remote_url"
    done
    echo ""

    if [ ${#available_remotes[@]} -eq 1 ]; then
        # Chỉ có 1 remote, tự động chọn
        remote="${available_remotes[0]}"
        echo "Auto-selected remote: $remote"
    else
        # Có nhiều remotes, cho user chọn
        read -p "Select remote (1-${#available_remotes[@]}) [default: 1]: " remote_choice
        remote_choice=${remote_choice:-1}

        if [[ ! "$remote_choice" =~ ^[0-9]+$ ]] || [ "$remote_choice" -lt 1 ] || [ "$remote_choice" -gt ${#available_remotes[@]} ]; then
            echo "Invalid selection"
            exit 1
        fi

        remote="${available_remotes[$((remote_choice-1))]}"
    fi
fi

# Validate remote tồn tại
if ! git remote | grep -q "^${remote}$"; then
    echo "❌ Remote '$remote' does not exist"
    exit 1
fi

# Hiển thị thông tin confirm
echo ""
echo "════════════════════════════════════════"
echo "Remote: $remote ($(git remote get-url "$remote"))"
echo "Branch: $branch"
echo "Commit: $commit_message"
echo "Files: $files_text"
echo "════════════════════════════════════════"
echo ""
echo "Files to be committed:"
git diff --cached --name-status
echo ""
read -p "Proceed with commit & push? (y/n): " confirm

# Xử lý confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled"
    exit 0
fi

# Thực hiện commit (KHÔNG git add . - chỉ commit staged files)
git commit -m "$commit_message"

# Push với force-with-lease (an toàn hơn --force)
if git push -u "$remote" "$branch" --force-with-lease; then
    echo ""
    echo "✅ Successfully pushed to $remote/$branch"
else
    echo ""
    echo "❌ Push failed"
    exit 1
fi