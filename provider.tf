##############################################################################
# Terraform Providers
##############################################################################

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.56.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
  required_version = ">= 1.0.0"
}

##############################################################################


##############################################################################
# IBM Cloud Provider
##############################################################################

locals {
  location_lookup = yamldecode(file("./data/locations.yaml"))
  location        = local.location_lookup[var.power_workspace_location]
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = local.location.vpc_region
  ibmcloud_timeout = 60
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = local.location.region
  zone             = var.power_workspace_location
  alias            = "power"
}

##############################################################################
