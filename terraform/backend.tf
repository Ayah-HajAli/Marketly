terraform {
  backend "s3" {
    bucket         = "marketly-ayah"
    key            = "capstone/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "capstone-tf-locks"
    encrypt        = true
  }
}