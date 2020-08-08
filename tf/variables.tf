variable "tenancy_ocid" {
  type = string
}

variable "cidr_blocks" {
  type = map
  default = {
    "vcn"            = "172.16.0.0/16"
    "workers"        = "172.16.0.0/24"
    "load_balancers" = "172.16.1.0/24"
    "pods"           = "10.244.0.0/16"
    "services"       = "10.96.0.0/16"
  }
}
