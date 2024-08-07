variable "docker_image" {
    type        = string
    description = "Docker image URI."
}

variable "aws_region" {
    type        = string
    description = "AWS Region for the architecture to be build."
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "py-docker-hello-world-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}