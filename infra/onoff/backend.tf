terraform {
  backend "local" {
    path = "../states/onoff.tfstate"
  }
}
