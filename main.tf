# Define composite variables for resources
module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.1"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

resource "aws_elastic_beanstalk_application" "default" {
  name        = "${module.label.id}"
  description = "${var.description}"

  appversion_lifecycle {
    service_role           = "${var.create_service_role == "false" ? var.appversion_lifecycle_service_role_arn : data.aws_iam_role.appversion_lifecycle.arn }"
    max_count             = "${var.appversion_lifecycle_max_count}"
    delete_source_from_s3 = "${var.appversion_lifecycle_delete_source_from_s3}"
  }
  tags        = "${module.label.tags}"
}

data "aws_iam_role" "appversion_lifecycle" {
  name               = "${module.label.id}-appversion-lifecycle"
  depends_on = ["aws_iam_role.appversion_lifecycle"]
}

resource "aws_iam_role" "appversion_lifecycle" {
  name               = "${module.label.id}-appversion-lifecycle"
  count              = "${var.create_service_role == "true" ? 1 : 0}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "appversion_lifecycle" {
  name   = "${module.label.id}-appversion-lifecycle"
  role   = "${aws_iam_role.appversion_lifecycle.id}"
  count  = "${var.create_service_role == "true" ? 1 : 0}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BucketAccess",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::elasticbeanstalk-*",
        "arn:aws:s3:::elasticbeanstalk-*/*"
      ]
    }
  ]
}
POLICY
}

