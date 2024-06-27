terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.6.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "num_of_uuids" {
  default = 1
  type = number
}

resource "random_uuid" "test" {
  count = var.num_of_uuids
}

output "random_uuids" {
  value = random_uuid.test.*.result
}

provider "aws" {
}

resource "aws_instance" "web" {
  ami           = "ami-04f8d7ed2f1a54b14"
  instance_type = "t2.micro"

  tags = {
    Name = "TestEC2"
    ProvisionedBy = "Atlantis"
  }
}

output "instance_id" {
  value = aws_instance.web.id
}