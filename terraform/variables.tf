variable "aws_region" {
  default = "us-west-2"
}

variable "amis" {
  type = "map"
  default = {
    "us-west-2" = "ami-6460191c"
  }
}

variable "aws_profile" {
  default = "default"
}

variable "aws_key_pair_file" {
  default = "C:/users/galen/.ssh/galen_success.pem"
}

variable "aws_key_pair_name" {
  default = "galen_success"
}

variable "aws_image_user" {
  default = "ubuntu"
}

variable "habitat_origin" {
  default = "galenemery"
}

variable "env" {
  default = "dev"
}

variable "bldr_url" {
  default = "https://bldr.habitat.sh"
}

variable "release_channel" {
  default = "stable"
}

variable "group" {
  default = "dev"
}

variable "update_strategy" {
  default = "at-once"
}

variable "tag_dept" {
  default = "success"
}

variable "tag_customer" {
  default = "galenemery"
}

variable "tag_project" {
  default = "ChefConf"
}

variable "tag_application" {
  default = "national-parks"
}

variable "tag_contact" {
  default = "galen"
}

variable "tag_ttl" {
  default = "8"
}
