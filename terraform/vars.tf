variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "vpc_block_primary" {
  description = "10.x.0.0/16 for primary range of the VPC address space"  
}

variable "vpc_block_secondary" {
  description = "10.x.0.0/16 for secondary range of the VPC address space"  
}

variable "app_name" {
  default = "todoozle"
}

variable "env" {
  description = "The env that this infrastructure defines, eg. staging"
}

variable "my_public_ip" {
  description = "My public IP to lock the pub subnet allowed access to"
}
