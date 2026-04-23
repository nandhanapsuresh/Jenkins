terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 5.0"
}
}
}
provider "aws" {
region = "ap-south-1"
}
resource "aws_s3_bucket" "demo_bucket" {
bucket = "jenkins-terraform-demo-nandhana"
}
resource "aws_vpc" "demo_vpc" {
cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public_subnet" {
vpc_id = aws_vpc.demo_vpc.id
cidr_block = "10.0.1.0/24"
}
resource "aws_instance" "ec2" {
ami = "ami-070e5bd3ff10324f8"
instance_type = "t3.micro"
}

