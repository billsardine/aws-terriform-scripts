#################################################################################################################################
#Internet VPC & Subnet
#################################################################################################################################

resource "aws_vpc" "inet_vpc" {
  cidr_block           = "${var.ip_prefix}.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name               = "vpc-${var.project_name}"
  }
}

resource "aws_subnet" "inet_gateway_subnet" {
  vpc_id            = aws_vpc.inet_vpc.id
  cidr_block        = "${var.ip_prefix}.128/26"
  availability_zone = var.availability_zone 
  tags = {
    Name            = "sn-${var.project_name}-public"
  }
}

resource "aws_subnet" "inet_private_subnet" {
  vpc_id            = aws_vpc.inet_vpc.id
  cidr_block        = "${var.ip_prefix}.0/26"
  availability_zone = var.availability_zone
  tags = {
    Name            = "sn-${var.project_name}-private"
  }
}

resource "aws_subnet" "inet_tgw_subnet" {
  vpc_id            = aws_vpc.inet_vpc.id
  cidr_block        = "${var.ip_prefix}.192/26"
  availability_zone = var.availability_zone
  tags = {
    Name            = "sn-${var.project_name}-tgw"
  }
}

##################################################################################################################################
# Internet Gateway
##################################################################################################################################

resource "aws_internet_gateway" "inet_gw" {
  vpc_id = aws_vpc.inet_vpc.id
  tags = {
    Name       = "igw-${var.project_name}"
  }
}

resource "aws_internet_gateway_attachment" "inet_gw_attachment" {
  internet_gateway_id = aws_internet_gateway.inet_gw.id
  vpc_id              = aws_vpc.inet_vpc.id
}

##################################################################################################################################
# NAT Gateway
##################################################################################################################################
resource "aws_nat_gateway" "inet_natgw" {
  allocation_id = aws_eip.inet-natgw-eip.id
  subnet_id     = aws_subnet.inet_gateway_subnet.id
  depends_on    = [aws_internet_gateway.inet_gw]
  tags = {
    Name        = "natgw-${var.project_name}"
  }
}

resource "aws_eip" "inet-natgw-eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.inet_gw]
  tags = {
    Name      = "natgw-eip-${var.project_name}"
  }
}

##################################################################################################################################
# TGW attachments
##################################################################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "inet_tgw_attachment" {
  subnet_ids         = [aws_subnet.tgw_subnet.id]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.inet_vpc.id   
  tags = {
    Name             = "tgw-attachment-${var.project_name}"
  }
}

##################################################################################################################################
# Routing Tables and Routes
##################################################################################################################################

resource "aws_route_table" "inet_private_routes" {
  vpc_id = aws_vpc.inet_vpc.id
  tags = {
    Name       = "rt-${var.project_name}-private"
  }
}

resource "aws_route" "private_10_route" {
  route_table_id         = aws_route_table.inet_private_routes.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "private_172_route" {
  route_table_id         = aws_route_table.inet_private_routes.id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "private_192_route" {
  route_table_id         = aws_route_table.inet_private_routes.id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "private_inet_internet_access" {
  route_table_id         = aws_route_table.inet_private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.inet_natgw.id
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.inet_vpc.id
  tags = {
    Name       = "rt-${var.project_name}-public"
  }
}

resource "aws_route" "public_10_route" {
  route_table_id         = aws_route_table.public_routes.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "public_172_route" {
  route_table_id         = aws_route_table.public_routes.id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "public_192_route" {
  route_table_id         = aws_route_table.public_routes.id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "public_inet_internet_access" {
  route_table_id         = aws_route_table.inet_private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gw.id
}

##################################################################################################################################
# Attach routes to subnets
##################################################################################################################################

resource "aws_route_table_association" "private_nets" {
  subnet_id      = aws_subnet.inet_private_subnet.id
  route_table_id = aws_route_table.inet_private_routes.id
}

resource "aws_route_table_association" "tgw_nets" {
  subnet_id      = aws_subnet.inet_tgw_subnet.id
  route_table_id = aws_route_table.inet_private_routes.id
}

resource "aws_route_table_association" "public_nets" {
  subnet_id      = aws_subnet.inet_gateway_subnet.id
  route_table_id = aws_route_table.public_routes.id
}

##################################################################################################################################
# Security Groups for instances
##################################################################################################################################

# Security group for internal access

resource "aws_security_group" "allow_internal" {
  name   = "private-sg-${var.project_name}-internal-nets-only"
  description = "Allow all inbound internal traffic and all outbound traffic"
  vpc_id = aws_vpc.inet_vpc.id
  tags = {
    Name       = "private-sg-${var.project_name}-internal-nets-only"
  }
}  

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_out_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_allow_10_0_0_0_in_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "10.0.0.0/8"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_allow_172_16_0_0_in_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "172.16.0.0/12"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_allow_192_169_0_0_in_ipv4" {
  security_group_id = aws_security_group.allow_internal.id
  cidr_ipv4         = "192.168.0.0/16"
  ip_protocol       = "-1"
}
