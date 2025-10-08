#!/bin/bash

# Default branch là branch hiện tại
branch=$(git rev-parse --abbrev-ref HEAD)

if [ -n "$1" ]; then
    branch="$1"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "$branch" ]; then
        echo "Switching to branch: $branch"
        git checkout $branch || { echo "Failed to checkout $branch"; exit 1; }
    fi
fi

# Lấy thông tin Git
remote=$(git remote | head -n 1)
changed_files=$(git diff --name-only --cached)
stats=$(git diff --cached --stat | tail -n 1)

# Parse số lượng files từ stats
if [[ $stats =~ ([0-9]+)\ file ]]; then
    file_count="${BASH_REMATCH[1]}"
    files_text="$file_count files"
else
    files_text="No files"
fi

# Kiểm tra AWS credentials
use_ai=false
if aws sts get-caller-identity &>/dev/null; then
    use_ai=true
fi

# Tạo commit message
if [ "$use_ai" = true ]; then
    # Lấy diff content
    diff_content=$(git diff --cached | head -c 10000)
    
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

# Hiển thị thông tin confirm
echo ""
echo "Remote: $remote"
echo "Branch: $branch"
echo "Commit message: $commit_message"
echo "Files changed: $files_text"
echo ""
read -p "Proceed? (y/n): " confirm

# Xử lý confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    exit 0
fi

# Thực hiện commit và push
git add .
git commit -m "$commit_message"

if git push -u origin $branch --force-with-lease; then
    echo "Changes pushed to $branch branch"
else
    echo "Push failed"
    exit 1
fi