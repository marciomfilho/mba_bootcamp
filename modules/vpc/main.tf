resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = element(var.azs, index(var.public_subnets, each.value))

  tags = {
    Name = "${var.name}-public-${each.value}"
  }
}

resource "aws_subnet" "private_app" {
  for_each = toset(var.private_app_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(var.azs, index(var.private_app_subnets, each.value))

  tags = {
    Name = "${var.name}-private-app-${each.value}"
  }
}

resource "aws_subnet" "private_data" {
  for_each = toset(var.private_data_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(var.azs, index(var.private_data_subnets, each.value))

  tags = {
    Name = "${var.name}-private-data-${each.value}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count      = length(var.azs)
  vpc        = true
  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "this" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public)[*].id, count.index)

  tags = {
    Name = "${var.name}-nat-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "${var.name}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id = each.value.id
  route_table_id = element(
    aws_route_table.private[*].id,
    index(var.private_app_subnets, each.value.cidr_block)
  )
}

resource "aws_route_table_association" "private_data" {
  for_each = aws_subnet.private_data

  subnet_id = each.value.id
  route_table_id = element(
    aws_route_table.private[*].id,
    index(var.private_data_subnets, each.value.cidr_block)
  )
}
