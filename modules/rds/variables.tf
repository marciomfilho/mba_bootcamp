variable "db_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_data_subnets" {
  type = list(string)
}
