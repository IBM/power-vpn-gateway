terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.56.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
  }
  required_version = ">= 1.0.0"
}
