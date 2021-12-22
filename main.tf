# provider
provider "aws" {   
    region  = var.region
}

# vpc
resource “aws_vpc” “main” { 
 cidr_block = var.vpc_cidr 
 tags = { 
          Project = “stockbit-devops” 
          Name = “my_vpc” 
        }
}

# public subnet
resource "aws_subnet" "pub_sub" {  
vpc_id                  = aws_vpc.main.id  
cidr_block              = var.pub_sub_cidr_block  
availability_zone       = "ap-southeast-3" 
map_public_ip_on_launch = true  
tags = {    
         Project = "stockbit-devops"   
         Name = "public_subnet"
      }
}

# private subnet
resource "aws_subnet" "prv_sub" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.prv_sub_cidr_block
  availability_zone       = "ap-southeast-3a"
  map_public_ip_on_launch = false
tags = {
    Project = "stockbit-devops"
    Name = "private_subnet" 
 }
}

# public route table
resource "aws_route_table" "pub_sub_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
   }
    tags = {
    Project = "stockbit-devops"
    Name = "public subnet route table" 
 }
}

resource "aws_route_table_association" "internet_for_pub_sub" {
  route_table_id = aws_route_table.pub_sub_rt.id
  subnet_id      = aws_subnet.pub_sub.id
}

# internet gateway
resource "aws_internet_gateway" "igw" {  
   vpc_id = aws_vpc.main.id   
   tags = {    
            Project = "stockbit-devops"   
            Name = "internet gateway"
          }
}

# NAT Gateway  
resource "aws_eip" "eip_natgw" {  
     count = "1"
}

resource "aws_nat_gateway" "natgateway" {  
     count         = "1"  
     allocation_id = aws_eip.eip_natgw[count.index].id  
     subnet_id     = aws_subnet.prv_sub.id
}

# private route table
resource "aws_route_table" "prv_sub_rt" {
  count  = "1"
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway[count.index].id
  }
  tags = {
    Project = "stockbit-devops"
    Name = "private subnet route table" 
 }
}

resource "aws_route_table_association" "pri_sub_to_natgw" {
  count          = "1"
  route_table_id = aws_route_table.prv_sub_rt[count.index].id
  subnet_id      = aws_subnet.prv_sub.id
}

# Launch config
resource "aws_launch_configuration" "my-launch-config" {
  name_prefix   = "my-launch-config"
  image_id      =  var.ami
  instance_type = "t2.medium"
  key_name = var.keyname
  
lifecycle {
        create_before_destroy = true
     }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ASG-stockbit" {
  name       = "ASG-stockbit"
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  health_check_type  = "EC2"
  launch_configuration = aws_launch_configuration.my-launch-config.name
  vpc_zone_identifier = ["${aws_subnet.prv_sub.id}"]
  
 tag {
       key                 = "Name"
       value               = "ASG-stockbit"
       propagate_at_launch = true
    }
}

resource "aws_autoscaling_policy" "ASG-up" {
    name = "ASG-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ASG-stockbit.name}"
}

resource "aws_autoscaling_policy" "ASG-down" {
    name = "ASG-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ASG-stockbit.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu-high" {
    alarm_name = "cpu-high-stockbit"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "45"
    alarm_description = "This metric monitors ec2 cpu for high utilization on stockbit host"
    alarm_actions = [
        "${aws_autoscaling_policy.ASG-up.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.ASG-stockbit.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "cpu-low" {
    alarm_name = "cpu-low-stockbit"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "44"
    alarm_description = "This metric monitors ec2 mcpu for low utilization on stockbit hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.ASG-down.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.ASG-stockbit.name}"
    }
}