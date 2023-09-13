#defining the key pair 
resource "aws_key_pair" "andlanc-dev-keypair" {
  key_name   = "andlanc_dev_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

#creating the vpc
resource "aws_vpc" "andlanc-dev-vpc" {
  cidr_block = var.andlanc-dev-cidr

  tags = {
    Name = "andlanc-dev-vpc"
  }
}

#creating internet gateway for the vpc
resource "aws_internet_gateway" "andlanc-dev-internet-gateway" {
  vpc_id = aws_vpc.andlanc-dev-vpc.id

  tags = {
    Name = "andlanc-dev-internet-gateway"
  }
}

#creating the route table
resource "aws_route_table" "andlanc-dev-route-table" {
  vpc_id = aws_vpc.andlanc-dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.andlanc-dev-internet-gateway.id
  }

  tags = {
    Name = "andlanc-dev-route-table"
  }
}

#creating the subnet (public subnet)
resource "aws_subnet" "andlanc-dev-subnet" {
  vpc_id            = aws_vpc.andlanc-dev-vpc.id
  cidr_block        = var.andlanc-dev-subnet-cidr
  availability_zone = "us-east-2a"

  tags = {
    Name = "andlanc-dev-subnet"
  }
}

#associate subnet to route table
resource "aws_route_table_association" "andlanc-dev-route-table-association" {
  subnet_id      = aws_subnet.andlanc-dev-subnet.id
  route_table_id = aws_route_table.andlanc-dev-route-table.id
}

#creating your security group
resource "aws_security_group" "andlanc-dev-allow-web-traffic" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.andlanc-dev-vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "andlanc-dev-allow-web-traffic"
  }
}

#creating your network interface
resource "aws_network_interface" "andlanc-dev-nic" {
  subnet_id       = aws_subnet.andlanc-dev-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.andlanc-dev-allow-web-traffic.id]

}

#creating and assigning your elastic ip 
resource "aws_eip" "andlanc-dev-test-eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.andlanc-dev-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.andlanc-dev-internet-gateway]
}

#creating the ubuntu server (instance) and launching your webserver
resource "aws_instance" "andlanc-dev" {
  ami               = "ami-053b0d53c279acc90"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"

  network_interface {
    network_interface_id = aws_network_interface.andlanc-dev-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo bash -c 'echo you have installed and started your webserver > /var/www/html/index.html'
    EOF

  tags = {
    Name = "andlanc-dev"
  }
}


