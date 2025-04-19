#################################################################################################################################
#Application VPC & Subnet
#################################################################################################################################

resource "aws_vpc" "app_vpc" {
#  count                = 1
  cidr_block           = "${var.ip_prefix}.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name       = "vpc-${var.project_name}"
    owner      = var.owner
#    pod        = "pod${var.pod_number}"
  }
}

resource "aws_subnet" "public_subnet" {
#  count             = 1
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "${var.ip_prefix}.0/26"
  availability_zone = var.availability_zone 
  tags = {
    Name       = "sn-${var.project_name}-public"
    owner      = var.owner
#    pod        = "pod${var.pod_number}"
  }
}

resource "aws_subnet" "private_subnet" {
#  count              = 1
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "${var.ip_prefix}.64/26"
  availability_zone = var.availability_zone
#  availability_zone = "us-east-1a"
  tags = {
    Name       = "sn-${var.project_name}-private"
    owner      = var.owner
#    pod        = "pod${var.pod_number}"
  }
}

resource "aws_subnet" "tgw_subnet" {
#  count              = 1
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "${var.ip_prefix}.192/26"
  availability_zone = var.availability_zone
#  availability_zone = "us-east-1a"
  tags = {
    Name       = "sn-${var.project_name}-tgw"
    owner      = var.owner
#    pod        = "pod${var.pod_number}"
  }
}
