provider "tfe" {
  hostname = "app.terraform.io"
  token = var.tfc_token 
  version  = "~> 0.30.2"
}