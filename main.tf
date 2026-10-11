locals {
  common_tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "Terraform"
  })
  singapore_name = "${var.project_name}-singapore"
  usa_name       = "${var.project_name}-usa"
  paris_name     = "${var.project_name}-paris"
}
