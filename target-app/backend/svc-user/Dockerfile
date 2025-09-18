# 1. Build 단계 (Maven으로 jar 빌드)
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# 2. Run 단계 (실행 환경: JRE)
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

# 3. 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
