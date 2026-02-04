variable "lab_role_arn" {
  type    = string
  default = "arn:aws:iam::167582247690:role/LabRole"
}

variable "region" {
  type    = string
  default = "sa-east-1"
}

variable "db_master_password" {
  type      = string
  sensitive = true
}
