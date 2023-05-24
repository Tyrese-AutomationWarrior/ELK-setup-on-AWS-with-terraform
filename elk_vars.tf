
variable "AWS_REGION" {
    default = "ap-south-1"
}
# Your Key Name here
variable "KEY_NAME" {
    type = string 
    default = ""
}
# Your Public Key Path Here
variable "PUBLIC_KEY_PATH" {
    description = "Public Key Path"
    default = ""
}
# Your Private Key Path Here
variable "PRIVATE_KEY_PATH" {
    description = "Private Key Path"
    default = ""
}

variable "ENVIRONMENT" {
    default = "Development"
}

variable "elk_ports" {
    type = list(number)
    default = [9200, 5601, 22]
}

variable "INSTANT_TYPE" {
    default = "m4.large"
}

variable "SERVER_USERNAME" {
    default = "ubuntu"
}
# Some AMI may throw errors. Juggle amongst options 
variable "AMIS" {
    type = map
    default = {
        us-east-1 = "ami-053b0d53c279acc90"
        us-east-2 = "ami-024e6efaf93d85776"
        us-west-1 = "ami-0f8e81a3da6e2510a"
        eu-west-1 = "ami-01dd271720c1ba44f"
        ap-south-1 = "ami-0fd48e51ec5606ac1"
    }
}
