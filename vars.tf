variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "UK South"
}

variable "username" {
  description = "The username for the virtual machine to be created."
}

variable "password" {
  description = "The password for the username of the virtual machine to be created."
}

variable "counter" {
  description = "The number of VM's to create to host the Web Service"
  default = "2"
}
