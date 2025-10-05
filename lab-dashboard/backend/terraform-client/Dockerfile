FROM eclipse-temurin:17-jre-alpine

# Install dependencies including wget and unzip for Terraform installation
RUN apk add --no-cache bash wget unzip

# Install Terraform
ARG TERRAFORM_VERSION=1.7.0
RUN wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -O /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    rm /tmp/terraform.zip

ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} /opt/chaos-dashboard/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/opt/chaos-dashboard/app.jar"]
