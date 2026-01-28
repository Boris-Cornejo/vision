provider "aws" {
  region = var.aws_region
}

############################################
# 1) Dedicated IAM user (non-admin)
############################################
resource "aws_iam_user" "visionai_textract" {
  name = var.iam_user_name
}

############################################
# 2) Inline policy attached to the user
#    Name is prefixed tenant_ (required)
############################################
data "aws_iam_policy_document" "visionai_textract_policy" {
  statement {
    sid     = "TextractOnly"
    effect  = "Allow"
    actions = var.textract_actions

    # Textract permissions typically use Resource "*"
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "visionai_textract_inline" {
  name   = var.iam_policy_name
  user   = aws_iam_user.visionai_textract.name
  policy = data.aws_iam_policy_document.visionai_textract_policy.json
}

############################################
# 3) Access key for the user
############################################
resource "aws_iam_access_key" "visionai_textract_key" {
  user = aws_iam_user.visionai_textract.name
}

############################################
# 4) Secrets Manager secret holding ONLY the SecretKey
#    (matches the doc’s SecretProviderClass alias usage)
############################################
resource "aws_secretsmanager_secret" "visionai_textract_secret" {
  name       = var.secretsmanager_secret_name
  kms_key_id = var.secrets_kms_key_arn != "" ? var.secrets_kms_key_arn : null
}

resource "aws_secretsmanager_secret_version" "visionai_textract_secret_value" {
  secret_id     = aws_secretsmanager_secret.visionai_textract_secret.id
  secret_string = aws_iam_access_key.visionai_textract_key.secret
}
