terraform {
  backend "local" {
    path = "../states/static.tfstate"
  }
}
