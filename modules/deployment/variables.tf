variable "source_dir" {
  description = "The function folder to be archived"
  type        = "string"
}

variable "repository_url" {
  description = "The ecs repository url"
  type        = "string"
}

variable "registry_id" {
  description = "The ecs registry id"
  type        = "string"
}

variable "assume_role_arn" {
  description = "Role to assume"
  type        = "string"
  default     = ""
}

# depends_on workaround

variable "depends_on" {
  description = "Helper variable to simulate depends_on for terraform modules"
  default     = []
}
