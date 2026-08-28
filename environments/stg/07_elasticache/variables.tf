variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "elasticache_engine" {
  type    = string
  default = "redis"
}

variable "elasticache_engine_version" {
  type    = string
  default = "7.1"
}

variable "elasticache_node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "elasticache_num_cache_nodes" {
  type    = number
  default = 1
}

variable "elasticache_parameter_group_family" {
  type    = string
  default = "redis7"
}

variable "elasticache_port" {
  type    = number
  default = 6379
}
