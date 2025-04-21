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
  transit_gateway_id            = var.tgw_id
}

resource "aws_route" "private_172_route" {
  route_table_id         = aws_route_table.private_routes.id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id             = var.tgw_id
}

resource "aws_route" "private_192_route" {
  route_table_id         = aws_route_table.private_routes.id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id             = var.tgw_id
}

resource "aws_route" "ineternet_access" {
  route_table_id         = aws_route_table.private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id             = var.tgw_id
}

# Need to add inetgateway for public nets

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name       = "rt-${var.project_name}-public"
  }
}

resource "aws_route" "public_10_route" {
  route_table_id         = aws_route_table.public_routes.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id            = var.tgw_id
}

resource "aws_route" "public_172_route" {
  route_table_id         = aws_route_table.public_routes.id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id             = var.tgw_id
}

resource "aws_route" "public_192_route" {
  route_table_id         = aws_route_table.public_routes.id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id             = var.tgw_id
}

##################################################################################################################################
# Attach routes to subnets
##################################################################################################################################

resource "aws_route_table_association" "private_nets" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_routes.id
}

resource "aws_route_table_association" "tgw_nets" {
  subnet_id      = aws_subnet.tgw_subnet.id
  route_table_id = aws_route_table.private_routes.id
}

resource "aws_route_table_association" "public_nets" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_routes.id
}

##################################################################################################################################
# Security Groups for instances
##################################################################################################################################

# Security group for internal access

resource "aws_security_group" "allow_internal" {
  name   = "private-sg-${var.project_name}-internal-nets-only"
  description = "Allow all inbound internal traffic and all outbound traffic"
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name       = "private-sg-${var.project_name}-internal-nets-only"
  }
}  

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_out_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

resource "aws_vpc_security_group_ingress_rule" "allow_10_0_0_0_in_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "10.0.0.0/8"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_172_16_0_0_in_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "172.16.0.0/122"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_192_169_0_0_in_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "192.168.0.0/16"
  ip_protocol       = "-1"
}
