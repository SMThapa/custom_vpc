variable "ami" {
  default = "ami-0ecb62995f68bb549"
}
variable "instance_type" {
  default = "t2.nano"
}
variable "pub_subnet" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "pvt_subnet" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}
variable "az" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}