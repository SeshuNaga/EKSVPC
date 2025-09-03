provider "aws" {
    region = "ap-south-1"

  
}

terraform {
  backend "s3" {

    bucket = "seshunagabucket"
    dynamodb_table = "seshu"
    key = "terraform.tfstate"
    region = "ap-south-1"
    
  }
}
