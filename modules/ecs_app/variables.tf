variable "vpc_id" {
  type = string
}

variable "public_subnets_ids" {
  type = list(string)
}

variable "private_app_subnets" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

variable "container_image_pedidos" {
  type = string
}

variable "container_image_rastreamento" {
  type = string
}

variable "desired_count_pedidos" {
  type = number
}

variable "desired_count_rastreamento" {
  type = number
}

variable "app_port" {
  type    = number
  default = 8080
}
