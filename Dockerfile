FROM maven:3.8.5-openjdk-11
WORKDIR /app

COPY pom.xml .

RUN mvn verify --fail-never

COPY . .

CMD mvn spring-boot:run
