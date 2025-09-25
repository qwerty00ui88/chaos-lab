FROM eclipse-temurin:17-jre-alpine
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} /opt/chaos-dashboard/app.jar
EXPOSE 8090
ENTRYPOINT ["java","-jar","/opt/chaos-dashboard/app.jar"]
