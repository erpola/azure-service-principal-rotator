locals {
  prefix = lower("${var.environment}-${var.project}")

  tags = {
    environment     = var.environment
    project         = var.project
    creation_method = "terraform"
    repository      = ""
  }
}
