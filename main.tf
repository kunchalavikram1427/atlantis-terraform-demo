resource "random_uuid" "test" {
  count = var.num_of_uuids
}

resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = "ami-04f8d7ed2f1a54b14"
  instance_type = "t2.micro"

  tags = {
    Name          = "TestEC2"
    ProvisionedBy = "Atlantis"
  }
}