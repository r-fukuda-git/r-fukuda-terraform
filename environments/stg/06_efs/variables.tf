variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "efs_expected_storage_gb" {
  type    = number
  default = 10
}

variable "efs_performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "efs_throughput_mode" {
  type    = string
  default = "bursting"
}
