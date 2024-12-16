###########vpc #################

resource "aws_vpc" "tool" {
  cidr_block       = var.vpc_cidr_range
  instance_tenancy = "default"

  tags = {
    Name = "tool"
  }
}

#########subnet############

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.tool.id
  cidr_block        = var.subnet1_range
  availability_zone = var.az1

  tags = {
    Name = "basiton-host"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.tool.id
  cidr_block        = var.subnet2_range
  availability_zone = var.az2

  tags = {
    Name = "application_subnet"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.tool.id
  cidr_block        = var.subnet3_range
  availability_zone = var.az2

  tags = {
    Name = "kafka_subnet"
  }
}

resource "aws_subnet" "private3" {
  vpc_id            = aws_vpc.tool.id
  cidr_block        = var.subnet4_range
  availability_zone = var.az2

  tags = {
    Name = "database_subnet"
  }
}

##########Internet Gateway########

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.tool.id

  tags = {
    Name = "tool-igw"
  }
}

##########Elastic Ip################

resource "aws_eip" "elastic_ip" {
  tags = {
    Name = "EIP"
  }
}

#########NAT Gateway#########

# creation NAT GW
resource "aws_nat_gateway" "NAT" {
  connectivity_type = var.connection_type
  subnet_id         = aws_subnet.public.id
  allocation_id     = aws_eip.elastic_ip.id

  tags = {
    Name = "NAT_gateway"
  }
}


##############Route Table############

resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.tool.id
  route {
    cidr_block = var.rt_cidr_range
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public_RT"
  }
}

resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.tool.id
  route {
    cidr_block = var.rt_cidr_range
    gateway_id = aws_nat_gateway.NAT.id
  }
  tags = {
    Name = "Private_RT"
  }
}


##########Route Table Association#########

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private_RT.id
}

# security group for public

resource "aws_security_group" "publicSG" {

  vpc_id = aws_vpc.tool.id
  ingress {
    from_port   = var.all
    to_port     = var.all
    protocol    = var.anywhere
    cidr_blocks = [var.sg_cidr_range]
  }
  egress {
    from_port   = var.all
    to_port     = var.all
    protocol    = var.anywhere
    cidr_blocks = [var.sg_cidr_range]
  }

  tags = {
    Name = "publicSG"
  }
}

resource "aws_security_group" "privateSG" {

  vpc_id = aws_vpc.tool.id
  ingress {
    from_port   = var.all
    to_port     = var.all
    protocol    = var.anywhere
    cidr_blocks = [var.sg_cidr_range]
  }
  egress {
    from_port   = var.all
    to_port     = var.all
    protocol    = var.anywhere
    cidr_blocks = [var.sg_cidr_range]
  }

  tags = {
    Name = "privateSG"
  }
}

############Peering connection###########

/* data "aws_vpc" "default" {
  default = true
}

resource "aws_vpc_peering_connection" "tool_to_default" {
  vpc_id        = aws_vpc.tool.id
  peer_vpc_id   = data.aws_vpc.default.id
  auto_accept   = true

  tags = {
    Name = "tool-to-default-peering"
  }
}

resource "aws_route" "tool_to_default" {
  route_table_id         = aws_route_table.public_RT.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.tool_to_default.id
}

data "aws_route_table" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_route" "default_to_tool" {
  route_table_id         = data.aws_route_table.default.id
  destination_cidr_block = aws_vpc.tool.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.tool_to_default.id
}
*/

###########EC 2 Instance#################

resource "aws_instance" "public" {
  ami           = var.ami_id
  instance_type = var.ec2_micro
  key_name      = var.pem_key
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.publicSG.id]
  associate_public_ip_address = true

  tags = {
    Name = "basiton-host"
  }
}

resource "aws_instance" "private1" {
  ami           = var.ami_id
  instance_type = var.ec2_medium
  key_name      = var.pem_key
  subnet_id     = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.privateSG.id]

  tags = {
    Name = "application-host"
  }
}

resource "aws_instance" "private2" {
  ami           = var.ami_id
  instance_type = var.ec2_medium
  key_name      = var.pem_key
  subnet_id     = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.privateSG.id]

  tags = {
    Name = "kafka-host"
  }
}

resource "aws_instance" "private3" {
  ami           = var.ami_id
  instance_type = var.ec2_medium
  key_name      = var.pem_key
  subnet_id     = aws_subnet.private3.id
  vpc_security_group_ids = [aws_security_group.privateSG.id]

  tags = {
    Name = "database-host"
  }
}

terraform {
  backend "s3" {
    bucket         = "yuvraj-ki-tf-ki-balti"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
  }
}
