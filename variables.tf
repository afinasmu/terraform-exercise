variable "ami"{
 type = string
  default = "ami-04505e74c0741db8d"
}
variable "keyname"{
  default = "my-private-key"
}
variable "region" {
  type        = string
  default     = "ap-southeast-3"
  description = "default region"
}

variable "vpc_cidr" {
  type        = string
  default     = "172.16.0.0/16"
  description = "default vpc_cidr_block"
}

variable "pub_sub_cidr_block"{
   type        = string
   default     = "172.16.1.0/24"
}

variable "prv_sub_cidr_block"{
   type        = string
   default     = "172.16.3.0/24"
}
