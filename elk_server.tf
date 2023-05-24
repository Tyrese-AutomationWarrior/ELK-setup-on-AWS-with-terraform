# Use remote backend when working with a group
# terraform {
#     backend "s3" {
#         bucket = "my-bucket-name"
#         key = "sample/bucket_path"
#         region = "us-east-1"  # Specify region
#     }
# }

# Initialize Provider
provider "aws" {
  region     = var.AWS_REGION 
}

# Specify key-pair path (create key in a directory with $ ssh-keygen -t <key_name>)
resource "aws_key_pair" "elk_srv_key" {
    key_name = var.KEY_NAME  
    public_key = file(var.PUBLIC_KEY_PATH)
}


resource "aws_security_group" "elk_sg" {
  name        = "${var.ENVIRONMENT}-elk-sg"
  description = "Allow ALL ELK Traffic"

  # Ingress ports for elasticsearch (9200), kibana (5601) and ssh (22)
 
  dynamic "ingress" {
    for_each = var.elk_ports
    content {
        from_port = ingress.value
        to_port = ingress.value
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  }
# Ingress port for logstash (5043, 5044), 
  ingress {
    from_port   = 5043
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Egress 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance 
resource "aws_instance" "elk_server" {
  ami           = lookup(var.AMIS, var.AWS_REGION)
  instance_type = var.INSTANT_TYPE    # "m4.large"
  availability_zone = "${var.AWS_REGION}a"
  key_name      = aws_key_pair.elk_srv_key.key_name

  vpc_security_group_ids = [
    aws_security_group.elk_sg.id,
  ]

  depends_on = [aws_security_group.elk_sg]
  
  tags = {
    Name = "${var.ENVIRONMENT}-elk-server"
  }
# Upload elasticsearch yml configuration to tmp directory
  provisioner "file" {
      source = "elasticsearch.yml"
      destination = "/tmp/elasticsearch.yml"
  }
# Upload kibana yml configuration to tmp directory
  provisioner "file" {
      source = "kibana.yml"
      destination = "/tmp/kibana.yml"
  }
# Upload apache log indexer to tmp directory 
  provisioner "file" {
      source = "apache-01.conf"
      destination = "/tmp/apache-01.conf"
  }
# upload installation bash script to tmp directory 
    provisioner "file" {
      source = "elk.sh"
      destination = "/tmp/elk.sh"
  }
# Add execute permission to the bash file and execute 
  provisioner "remote-exec" {
    inline = [
      "chmod +x    /tmp/elk.sh",
      "sudo sed -i -e 's/\r$//' /tmp/elk.sh",  # Remove the spurious CR characters.
      "sudo /tmp/elk.sh",
    ]
  }
# To connect to the instance, use ssh with the Private Key 
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.SERVER_USERNAME
    private_key = file(var.PRIVATE_KEY_PATH)
  }
}

# Elastic IP for the kibana 
resource "aws_eip" "elk_srv_ip" {
  instance = aws_instance.elk_server.id
}

# Connect to kibana dashboard using output public IP on port 5601 (pub_ip:5601)
output "elk_srv_public_ip" {
  value = aws_instance.elk_server.public_ip 
}