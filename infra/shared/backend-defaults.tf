locals {
  backend_defaults = {
    bucket         = "chaos-lab-terraform-state"
    dynamodb_table = "chaos-lab-terraform-locks"
    region         = "ap-northeast-2"
    workspaces     = {
      static = "static/terraform.tfstate"
      onoff  = "onoff/terraform.tfstate"
    }
  }
}
