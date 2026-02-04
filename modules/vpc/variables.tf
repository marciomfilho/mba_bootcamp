variable "name" {
  type        = string
  description = "Name prefix for VPC resources"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "List of Availability Zones"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
}

variable "private_app_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for private app subnets"
}

variable "private_data_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for private data subnets"
}
