############################################
# Network (optional - NOT used by the dev environment)
############################################
# A minimal public-subnet-only VPC. Deliberately has no NAT Gateway
# (NAT Gateway is billed per hour + per GB, i.e. NOT free-tier) so
# using this module costs nothing beyond the VPC itself, which is
# free. Every service used in dev (Lambda, DynamoDB, API Gateway, S3,
# CloudFront) is either serverless-and-unmanaged-network or reachable
# over the public AWS API endpoints, so dev does not call this
# module at all. It exists so a future environment that needs, say,
# RDS in private subnets has a starting point - add private subnets +
# a NAT Gateway (or NAT instance, or VPC endpoints, to stay cheaper)
# at that point.

resource "aws_vpc" "this" {
  count = var.enabled ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  count  = var.enabled ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  count                   = var.enabled ? length(var.public_subnet_cidrs) : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, { Name = "${var.name}-public-${count.index}" })
}

resource "aws_route_table" "public" {
  count  = var.enabled ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = var.enabled ? length(var.public_subnet_cidrs) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}
