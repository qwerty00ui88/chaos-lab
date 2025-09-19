terraform {
  backend "s3" {
    bucket         = "chaos-lab-terraform-state"
    key            = "static/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "chaos-lab-terraform-locks"
    encrypt        = true
  }
}
