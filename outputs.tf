output "random_uuids" {
  value = random_uuid.test.*.result
}

output "instance_id" {
  value = aws_instance.web.*.id
}