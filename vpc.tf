
module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = "${var.prefix}vpc"
  cidr            = "10.0.0.0/16"
  azs             = [local.azs[0], local.azs[1]]
  public_subnets  = ["10.0.101.0/24", "10.0.201.0/24", "10.0.102.0/24", "10.0.202.0/24"]
  private_subnets = ["10.0.103.0/24", "10.0.203.0/24"]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

