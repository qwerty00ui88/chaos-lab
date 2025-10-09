FROM eclipse-temurin:17-jre-alpine

# Install helper dependencies and AWS CLI for SSM lookups
RUN apk add --no-cache bash wget unzip aws-cli

# Install kubectl for ingress updates in apply.sh
ARG KUBECTL_VERSION=v1.29.3
RUN wget -q "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -O /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install Terraform
ARG TERRAFORM_VERSION=1.7.0
RUN wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -O /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    rm /tmp/terraform.zip

ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} /opt/chaos-dashboard/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/opt/chaos-dashboard/app.jar"]
