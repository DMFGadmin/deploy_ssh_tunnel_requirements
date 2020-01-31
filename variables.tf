variable "region" {
  description = "The region to deploy to"
}

variable "source_range1" {
  description = "who needs access to this instance over port 22"
}

variable "source_range2" {
  description = "who needs access to this instance over port 22"
}

variable "zone" {
  description = "which zone should the server be deployed"
}

variable "project_id" {
  description = "which project to deploy server into"
}

variable "ssh_tunnel_tags" {
  description = "tags to allow instances to talk to each other in the same subnet"
}

variable "external_ssh_access_tag" {
  description = "allows remote access of ssh server"
}