#Access AWS 

provider "aws" {
 region = "ap-southeast-2"
 access_key = "AKIA5AGZYOPEVJUXY4EC"
  secret_key = "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"
}

#Environment Variable 

#set up instance type
variable "instance_type_id01" {
  description = "Instance type to use"
  default = "t2.micro"
}

variable "instance_type_id02" {
  description = "Instance type to use"
  default = "t2.medium"
}


#set up application and database instance
variable "ami_id_bea" {
  description = "AMI ID BEA"
  default = "ami-0187e13df7843aacc"
}


variable "ami_id_bcs" {
  description = "AMI ID BCS"
  default = "ami-064880dd87d059fbc"
}

variable "ami_id_hzn" {
  description = "AMI ID HZN"
  default = "ami-0c72ea7384390b4ad"
}


variable "ami_db_id" {
  description = "AMI ID DB"
  default = "ami-04b4282556df6fd7b"
}

#JUMP server
variable "ami_db_jumpserver" {
  description = "AMI ID jumpserver"
  default = "ami-0d594bd859877003e"
}

variable "instance_count" {
  default = "3"
}


#Create VPC

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "my_vpc"
  }
}

#Create Private Subnet 
resource "aws_subnet" "subnet_pvt" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "subnet_pvt"
  }
}

#Create Public Subnet 
resource "aws_subnet" "subnet_pub" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "my_subnet_pub"
  }
}


resource "aws_internet_gateway" "igw_01" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_Igw01"
  }
}


#Routing table

resource "aws_route_table" "my_route_table_pub_01" {
  vpc_id = aws_vpc.my_vpc.id
   route  {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw_01.id
    }
   
  tags = {
    Name = "my_route_table_pub_01"
  }
}

resource "aws_route_table_association" "route_table_ass01" {
  subnet_id     = aws_subnet.subnet_pub.id
  route_table_id = aws_route_table.my_route_table_pub_01.id
}


#EIP 

#resource "aws_eip" "my_eip_bea01" {
#  vpc      = true
#  tags = { 
#	Name = "my_eip_bea01"
#	}
#}


#resource "aws_eip" "my_eip_bcs01" {
#  vpc      = true
#  tags = { 
#	Name = "my_eip_bcs01"
#	}
#}


#resource "aws_eip" "my_eip_hzn01" {
#  vpc      = true
#  tags = { 
#	Name = "my_eip_hzn01"
#	}
#}

resource "aws_eip" "my_eip_Jumpserver" {
  vpc      = true
  tags = { 
	Name = "Jumpserver"
	}
}



#resource "aws_eip_association" "eip_assoc_bea01" {
#  instance_id   = aws_instance.int_ami_id_bea.id
#  allocation_id = aws_eip.my_eip_bea01.id
#}

#resource "aws_eip_association" "eip_assoc_bcs01" {
#  instance_id   = aws_instance.int_ami_id_bcs.id
#  allocation_id = aws_eip.my_eip_bcs01.id
#}


#resource "aws_eip_association" "eip_assoc_hzn01" {
#  instance_id   = aws_instance.int_ami_id_hzn.id
#  allocation_id = aws_eip.my_eip_hzn01.id
#}

resource "aws_eip_association" "eip_assoc_Jumpserver" {
  instance_id   = aws_instance.int_ami_id_jumpserver.id
  allocation_id = aws_eip.my_eip_Jumpserver.id
}


#NAT Gateway
resource "aws_eip" "eip_nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip_nat.id
  subnet_id     = aws_subnet.subnet_pub.id
  #depends_on    = [aws_internet_gateway.internet-gw]
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
}

resource "aws_route_table_association" "private-rta" {
  subnet_id      = aws_subnet.subnet_pvt.id
  route_table_id = aws_route_table.private-rt.id
}


#resource "aws_network_interface" "network_interface_pvt" {
#  subnet_id   = aws_subnet.subnet_pvt.id
#  private_ips = ["10.0.1.10"]
#  tags = {
#    Name = "network_interface_pvt"
#  }
#}

#resource "aws_network_interface" "network_interface_pub" {
#  subnet_id   = aws_subnet.subnet_pub.id
#  private_ips = ["10.0.0.10"]
#  tags = {
#    Name = "network_interface_pub"
#  }
#}

#Create Security group for Application server and DB
resource "aws_security_group" "allow_sg" {
name = "allow_sg"
vpc_id = aws_vpc.my_vpc.id

ingress { 
description = "allow_ssh_sg"
from_port = 22
to_port   = 22
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_http_sg"
from_port = 80
to_port   = 80
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_http88_sg"
from_port = 88
to_port   = 88
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_httpDB_sg"
from_port = 1521
to_port   = 1521
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_httpNFS_sg"
from_port = 2049
to_port   = 2049
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_zoopkeeper01_sg"
from_port = 2181
to_port   = 2181
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_zoopkeeper02_sg"
from_port = 3888
to_port   = 3888
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_zoopkeeper03_sg"
from_port = 2888
to_port   = 2888
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

tags = {
Name = "allow_sg"
}



egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}




#Create Security group for HZN
resource "aws_security_group" "allow_hzn" {
name = "allow_hzn"
vpc_id = aws_vpc.my_vpc.id

ingress { 
description = "allow_ssh_hzn"
from_port = 1000
to_port   = 4000
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "allow_hzn"
}
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}





#Instance create 

resource "aws_instance" "int_ami_id_bea" {
   #instance_type = "t2.micro"
   instance_type = "${var.instance_type_id01}"
   ami = "${var.ami_id_bea}"
   subnet_id = aws_subnet.subnet_pvt.id
   key_name = "ansible_sydney"
   vpc_security_group_ids = [aws_security_group.allow_sg.id]
   user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo yum update -y
  sudo yum install apache2 -y 
  sudo yum install haproxy -y
  sudo yum install -y httpd httpd-tools mod_ssl 
  sudo amazon-linux-extras install ansible2
  yum install nginx -y
  yum install git -y
  echo "*** Completed Installing apache1"
  EOF
tags = {
	Name = "int_ami_id_bea"
}

volume_tags = {
	Name = "application_instance_private"
}
}

resource "aws_instance" "int_ami_id_bcs" {
  #instance_type = "t2.micro"
   instance_type = "${var.instance_type_id02}"
   ami = "${var.ami_id_bcs}"
   subnet_id = aws_subnet.subnet_pvt.id
   key_name = "ansible_sydney"
   vpc_security_group_ids = [aws_security_group.allow_sg.id]
    user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo yum update -y
  sudo yum install apache2 -y 
  sudo yum install haproxy -y
  sudo yum install -y httpd httpd-tools mod_ssl 
  sudo amazon-linux-extras install ansible2
  yum install nginx -y
  yum install git -y
  sudo systemctl start httpd
  echo "*** Completed Installing apache2"
  EOF
tags = {
	Name = "int_ami_id_bcs"
}

volume_tags = {
	Name = "application_instance_pub"
}
}

resource "aws_instance" "int_ami_id_hzn" {
  #instance_type = "t2.micro"
   instance_type = "${var.instance_type_id01}"
   ami = "${var.ami_id_hzn}"
   count = var.instance_count
   subnet_id = aws_subnet.subnet_pvt.id
   key_name = "ansible_sydney"
   vpc_security_group_ids = [aws_security_group.allow_hzn.id]
    user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo yum update -y
  sudo yum install apache2 -y 
  sudo yum install haproxy -y
  sudo yum install -y httpd httpd-tools mod_ssl 
  sudo amazon-linux-extras install ansible2
  yum install nginx -y
  yum install git -y
  sudo systemctl start httpd
  echo "*** Completed Installing apache2"
  EOF
tags = {
	Name = "int_ami_id_hzn"
}

volume_tags = {
	Name = "application_instance_pub"
}
}



resource "aws_instance" "databaseXE" {
#instance_type = "t2.micro"
   instance_type = "${var.instance_type_id02}"
   ami = "${var.ami_db_id}"
   subnet_id = aws_subnet.subnet_pvt.id
   key_name = "ansible_sydney"
   vpc_security_group_ids = [aws_security_group.allow_sg.id]
tags = {
	Name = "DatabaseXE"
}

volume_tags = {
	Name = "Database XE"
}
}


resource "aws_instance" "int_ami_id_jumpserver" {
   #instance_type = "t2.micro"
   instance_type = "${var.instance_type_id01}"
   ami = "${var.ami_id_bea}"
   subnet_id = aws_subnet.subnet_pub.id
   key_name = "ansible_sydney"
   vpc_security_group_ids = [aws_security_group.allow_sg.id]
   user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo yum update -y
  sudo yum install apache2 -y 
  sudo yum install haproxy -y
  sudo yum install -y httpd httpd-tools mod_ssl 
  sudo amazon-linux-extras install ansible2
  yum install nginx -y
  yum install git -y
  yum install -y ruby
  yum install -y aws-cli
  echo "*** Completed Installing apache1"
  EOF
tags = {
	Name = "int_ami_id_jumpserver"
}

volume_tags = {
	Name = "Jump_Server"
}
}

