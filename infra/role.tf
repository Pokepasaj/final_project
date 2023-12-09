resource "aws_iam_role" "role" {
  name = "kind-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

data "aws_iam_policy" "admin" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
resource "aws_iam_role_policy_attachment" "admin-attach" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.admin.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "kind-profile"
  role = aws_iam_role.role.name
}