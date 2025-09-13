resource "aws_eks_cluster" "this" {
  name     = "chaos-lab-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]
  }

  version = "1.29"

  tags = { Name = "chaos-lab-cluster" }
}
