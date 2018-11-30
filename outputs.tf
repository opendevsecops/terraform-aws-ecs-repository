output "url" {
  value = "${aws_ecr_repository.main.repository_url}"
}

output "registry_id" {
  value = "${aws_ecr_repository.main.registry_id}"
}
