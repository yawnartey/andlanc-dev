#andlanc-dev vpc cidr block definition
variable "andlanc-dev-cidr" {
  description = "andlanc-dev vpc cidr block"
  type        = string
  default     = "10.1.0.0/16" 
}

#andlanc-dev subnet cidr block definition
variable "andlanc-dev-subnet-cidr" {
  description = "andlanc-dev subnet cidr block"
  type        = string
  default     = "10.1.0.0/16" 
}