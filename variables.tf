variable "name" {
  description = "The name for this repository"
  type        = "string"
}

# depends_on workaround

variable "depends_on" {
  description = "Helper variable to simulate depends_on for terraform modules"
  default     = []
}
