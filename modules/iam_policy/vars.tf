variable "name" {
    default = "Test"
}

variable "description" {
    default = "Policy created by terraform"
}

variable "actions" {
    type = "list"
}

variable "resources" {
    default = [
        "*"
        ]
}
