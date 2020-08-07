resource "random_string" "build_name" {
  length  = 12
  number  = false
  upper   = false
  special = false
}

locals {
  build = file(format("%s/%s", var.source_dir, "/Dockerfile"))
}

resource "null_resource" "task_build" {
  triggers = {
    build = local.build
  }

  provisioner "local-exec" {
    working_dir = var.source_dir

    command = <<EOF
docker build -t ${random_string.build_name.result} .
EOF

  }
}

resource "null_resource" "task_tag" {
  triggers = {
    build = local.build
  }

  provisioner "local-exec" {
    working_dir = var.source_dir

    command = <<EOF
docker tag ${random_string.build_name.result}:latest ${var.repository_url}:latest
EOF

  }

  depends_on = [null_resource.task_build]
}

resource "null_resource" "task_push" {
  count = var.assume_role_arn == "" ? 1 : 0

  triggers = {
    build = local.build
  }

  provisioner "local-exec" {
    working_dir = var.source_dir

    environment = {
      REGISTRY_ID    = var.registry_id
      REPOSITORY_URL = var.repository_url
    }

    command = <<EOF
aws ecr get-login --no-include-email --registry-ids "$REGISTRY_ID" | /bin/sh
docker push "$REPOSITORY_URL:latest"
EOF

  }

  depends_on = [null_resource.task_tag]
}

resource "null_resource" "task_push_with_role" {
  count = var.assume_role_arn == "" ? 0 : 1

  triggers = {
    build = local.build
  }

  provisioner "local-exec" {
    working_dir = var.source_dir

    environment = {
      REGISTRY_ID     = var.registry_id
      REPOSITORY_URL  = var.repository_url
      ASSUME_ROLE_ARN = var.assume_role_arn
    }

    command = <<EOF
CONFIG=$(aws sts assume-role --role-arn "$ASSUME_ROLE_ARN" --role-session-name tf-tmp --output json)
export AWS_ACCESS_KEY_ID=$(echo "$CONFIG" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$CONFIG" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$CONFIG" | jq -r .Credentials.SessionToken)

aws ecr get-login --no-include-email --registry-ids "$REGISTRY_ID" | /bin/sh
docker push "$REPOSITORY_URL:latest"
EOF

  }

  depends_on = [null_resource.task_tag]
}

