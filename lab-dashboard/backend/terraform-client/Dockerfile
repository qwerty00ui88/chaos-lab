FROM eclipse-temurin:17-jre-alpine

RUN apk add --no-cache bash
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} /opt/chaos-dashboard/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/opt/chaos-dashboard/app.jar"]
