provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "skitamura-terraform-tfstate"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}
