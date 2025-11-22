resource "aws_s3_bucket" "app_bucket" {
  bucket = "web-bucket-sidilian-01"

  tags = {
    Name = "web server bucket"
  }
}
resource "aws_s3_object" "app_files" {
  for_each = fileset("${path.module}/../app", "**")

  bucket = aws_s3_bucket.app_bucket.id
  key    = each.value
  source = "${path.module}/../app/${each.value}"
  etag   = filemd5("${path.module}/../app/${each.value}")

  content_type = lookup(
    {
      "html" = "text/html"
      "css"  = "text/css"
      "js"   = "application/javascript"
      "json" = "application/json"
      "png"  = "image/png"
      "jpg"  = "image/jpeg"
      "jpeg" = "image/jpeg"
      "svg"  = "image/svg+xml"
      "ico"  = "image/x-icon"
      "txt"  = "text/plain"
    },
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "binary/octet-stream"
  )
}

resource "aws_vpc" "web_server" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc web server"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.web_server.id

  tags = {
    Name = "Internet Gateway"
  }
}

#public subnets
resource "aws_subnet" "pub_sub1" {
  vpc_id            = aws_vpc.web_server.id
  cidr_block        = var.pub_subnet[0]
  availability_zone = var.az[0]

  tags = {
    Name = "public subnet 1"
  }
}
resource "aws_subnet" "pub_sub2" {
  vpc_id            = aws_vpc.web_server.id
  cidr_block        = var.pub_subnet[1]
  availability_zone = var.az[1]

  tags = {
    Name = "public subnet 2"
  }
}

#define path to igw
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.web_server.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Route table for public subnets"
  }
}
#connect subnet1 to route
resource "aws_route_table_association" "rt_ass_pub1" {
  subnet_id      = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.rt.id
}
#connect subnet2 to route
resource "aws_route_table_association" "rt_ass_pub2" {
  subnet_id      = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.rt.id
}

#private subnets
resource "aws_subnet" "pvt_sub1" {
  vpc_id            = aws_vpc.web_server.id
  cidr_block        = var.pvt_subnet[0]
  availability_zone = var.az[0]

  tags = {
    Name = "private subnet 1"
  }
}
resource "aws_subnet" "pvt_sub2" {
  vpc_id            = aws_vpc.web_server.id
  cidr_block        = var.pvt_subnet[1]
  availability_zone = var.az[1]

  tags = {
    Name = "private subnet 2"
  }
}
#eip and nat for az 1
resource "aws_eip" "nat_eip_az_1" {
  domain = "vpc"

  tags = {
    Name = "Eip for Nat"
  }
}
resource "aws_nat_gateway" "nat_az_1" {
  allocation_id = aws_eip.nat_eip_az_1.id
  subnet_id     = aws_subnet.pub_sub1.id

  tags = {
    Name = "Nat Gateway 1"
  }
}
#eip and nat for az 2
resource "aws_eip" "nat_eip_az_2" {
  domain = "vpc"

  tags = {
    Name = "Eip for Nat"
  }
}
resource "aws_nat_gateway" "nat_az_2" {
  allocation_id = aws_eip.nat_eip_az_2.id
  subnet_id     = aws_subnet.pub_sub2.id
  tags = {
    Name = "Nat Gateway 2"
  }
}

#define path for nat1
resource "aws_route_table" "nat_rt_1" {
  vpc_id = aws_vpc.web_server.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az_1.id
  }
  tags = {
    Name = "route table for nat_az_1"
  }
}
#define path for nat2
resource "aws_route_table" "nat_rt_2" {
  vpc_id = aws_vpc.web_server.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az_2.id
  }
  tags = {
    Name = "route table for nat_az_2"
  }
}

#connecting route_table with pvt subnet 1
resource "aws_route_table_association" "pvt_rt_ass_1" {
  subnet_id      = aws_subnet.pvt_sub1.id
  route_table_id = aws_route_table.nat_rt_1.id
}
#connecting route_table with pvt subnet 2
resource "aws_route_table_association" "pvt_rt_ass_2" {
  subnet_id      = aws_subnet.pvt_sub2.id
  route_table_id = aws_route_table.nat_rt_2.id
}

#bastion sg
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.web_server.id
  name   = "bastion-sg"

  ingress {
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
}
#bastion host
resource "aws_instance" "bastion_host" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.pub_sub1.id
  associate_public_ip_address = true
  key_name                    = "test1"
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "Bastion Host Instance"
  }
}

#alb sg
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.web_server.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#filter the inbound network
resource "aws_security_group" "ec2_sg" {
  name   = "instance sg"
  vpc_id = aws_vpc.web_server.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server_az_1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = "test1"
  subnet_id              = aws_subnet.pvt_sub1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  #connecting the permission to access s3
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  #need executeable permission 
  user_data_base64 = filebase64("${path.module}/uploadFile.sh")

  tags = {
    Name = "web server host connected with s3"
  }
}
resource "aws_instance" "web_server_az_2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = "test1"
  subnet_id              = aws_subnet.pvt_sub2.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  #connecting the permission to access s3
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  #need executeable permission 
  user_data_base64 = filebase64("${path.module}/uploadFile.sh")

  tags = {
    Name = "web server host connected with s3"
  }
}
resource "aws_lb" "alb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.pub_sub1.id,
    aws_subnet.pub_sub2.id
  ]

  tags = {
    Name = "ALB"
  }
}
resource "aws_lb_target_group" "alb_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.web_server.id

  health_check {
    path = "/"
  }
}
resource "aws_lb_target_group_attachment" "alb_target_1" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.web_server_az_1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "alb_target_2" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.web_server_az_2.id
  port             = 80
}
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}