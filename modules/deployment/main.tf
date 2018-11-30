resource "random_string" "build_name" {
  length  = 12
  number  = false
  upper   = false
  special = false
}

locals {
  build = "${file(format("%s/%s", var.source_dir, "/Dockerfile"))}"
}

resource "null_resource" "task_build" {
  triggers {
    build = "${local.build}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_dir}"

    command = "docker build -t ${random_string.build_name.result} ."
  }
}

resource "null_resource" "task_tag" {
  triggers {
    build = "${local.build}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_dir}"

    command = "docker tag ${random_string.build_name.result}:latest ${var.repository_url}:latest"
  }

  depends_on = ["null_resource.task_build"]
}

resource "null_resource" "task_login" {
  count = "${var.assume_role_arn == "" ? 1 : 0}"

  triggers {
    build = "${local.build}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_dir}"

    command = <<EOF
  aws ecr get-login --no-include-email --registry-ids ${var.registry_id} | /bin/sh
EOF
  }

  depends_on = ["null_resource.task_tag"]
}

resource "null_resource" "task_push" {
  count = "${var.assume_role_arn == "" ? 1 : 0}"

  triggers {
    build = "${local.build}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_dir}"

    command = "docker push ${var.repository_url}:latest"
  }

  depends_on = ["null_resource.task_login"]
}

resource "null_resource" "task_login_with_role" {
  count = "${var.assume_role_arn == "" ? 0 : 1}"

  triggers {
    build = "${local.build}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_dir}"

    command = <<EOF
  CONFIG=$(aws sts assume-role --role-arn ${var.assume_role_arn} --role-session-name tf-tmp --output json)
  export AWS_ACCESS_KEY_ID=$$(echo $CONFIG | jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$$(echo $CONFIG | jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$$(echo $CONFIG | jq -r .Credentials.SessionToken)
  aws ecr get-login --no-include-email --registry-ids ${var.registry_id} | /bin/sh
EOF
  }

  depends_on = ["null_resource.task_tag"]
}

resource "null_resource" "task_push_with_role" {
  count = "${var.assume_role_arn == "" ? 0 : 1}"

  triggers {
    build = "${local.build}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_dir}"

    command = "docker push ${var.repository_url}:latest"
  }

  depends_on = ["null_resource.task_login_with_role"]
}
