variable "region" {
  description = "AWS Region"
  type = string
  default = "eu-central-1"
}

variable "project_name" {
  description = "Prefix"
  type = string
  default = "tf-lab"
}

variable "profile" {
  description = "AWS Profile"
  type = string
  default = "les_admin_tf"
}