#################################################################################################################################
#Application VPC & Subnet
#################################################################################################################################

resource "aws_vpc" "app_vpc" {
  cidr_block           = "${var.ip_prefix}.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name       = "vpc-${var.project_name}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "${var.ip_prefix}.0/26"
  availability_zone = var.availability_zone 
  tags = {
    Name       = "sn-${var.project_name}-public"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "${var.ip_prefix}.64/26"
  availability_zone = var.availability_zone
  tags = {
    Name       = "sn-${var.project_name}-private"
  }
}

resource "aws_subnet" "tgw_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "${var.ip_prefix}.192/26"
  availability_zone = var.availability_zone
  tags = {
    Name       = "sn-${var.project_name}-tgw"
  }
}

##################################################################################################################################
# TGW attachments
##################################################################################################################################


resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  subnet_ids         = [aws_subnet.tgw_subnet.id]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.app_vpc.id   
  tags = {
    Name       = "tgw-attachment-${var.project_name}"
  }
}
##################################################################################################################################
# Routing Tables and Routes
##################################################################################################################################

resource "aws_route_table" "private_routes" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name       = "rt-${var.project_name}-private"
  }
}

resource "aws_route" "private_10_route" {
  route_table_id         = aws_route_table.private_routes.id
  destination_cidr_block = "10.0.0.0/8"
  gateway_id             = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
}

resource "aws_route" "private_172_route" {
  route_table_id         = aws_route_table.private_routes.id
  destination_cidr_block = "172.16.0.0/12"
  gateway_id             = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
}

resource "aws_route" "private_192_route" {
  route_table_id         = aws_route_table.private_routes.id
  destination_cidr_block = "192.168.0.0/16"
  gateway_id             = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
}