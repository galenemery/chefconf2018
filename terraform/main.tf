terraform {
  required_version = "> 0.11.0"
}

provider "aws" {
  profile                 = "${var.aws_profile}"
  shared_credentials_file = "~/.aws/credentials"
  region                  = "${var.aws_region}"
}

resource "random_id" "national_parks_id" {
  byte_length = 4
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "${var.aws_key_pair_name}_${random_id.national_parks_id.hex}_national_parks"
  }
}

data "aws_availability_zones" "all" {}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

## Creating Launch Configuration
resource "aws_launch_configuration" "national-parks" {
  image_id               = "${lookup(var.amis, var.aws_region)}"
  instance_type          = "m4.large"
  security_groups        = ["${aws_security_group.national-parks.id}"]
  key_name               = "${var.aws_key_pair_name}"
  user_data = <<-EOF
    #!/bin/bash
    iid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    echo node_name \"$iid\" | sudo tee -a /etc/chef/client.rb
    sudo rm /var/chef/cache/data_collector_metadata.json
    sudo chef-client -o recipe[quarantine-demo::harden]
    sudo chef-client -r role[quarantine-demo::audit]
    sudo systemctl daemon-reload
    sudo systemctl start hab-sup
    sudo systemctl enable hab-sup
    sudo hab svc load galenemery/national-parks --group dev --channel stable --strategy at-once --bind database:np-mongodb.dev
    EOF
  lifecycle {
    create_before_destroy = true
  }
}

## Creating AutoScaling Group
resource "aws_autoscaling_group" "national-parks" {
  launch_configuration = "${aws_launch_configuration.national-parks.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  vpc_zone_identifier = ["${aws_subnet.default.id}"]
  min_size = 3
  max_size = 3
  load_balancers = ["${aws_elb.national-parks.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-national-parks"
    propagate_at_launch = true
  }
}

### Creating ELB
resource "aws_elb" "national-parks" {
  name = "terraform-asg-national-parks-elb"
  security_groups = ["${aws_security_group.elb.id}"]
  subnets = ["${aws_subnet.default.id}"]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 2
    interval = 10
    target = "HTTP:8080/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }
}

////////////////////////////////
// Firewalls

resource "aws_security_group" "national-parks" {
  name        = "${var.aws_key_pair_name}-${random_id.national_parks_id.hex}-national-parks"
  description = "National Parks"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9631
    to_port     = 9631
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9638
    to_port     = 9638
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9631
    to_port     = 9631
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9638
    to_port     = 9638
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    X-Contact     = "${var.aws_key_pair_name} <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

resource "aws_security_group" "null_route" {
  name        = "${var.aws_key_pair_name}-${random_id.national_parks_id.hex}-null_route"
  description = "Null Route for Quarantined Systems"
  vpc_id      = "${aws_vpc.default.id}"
  tags {
    X-Contact     = "${var.aws_key_pair_name} <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }

}

resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Terraform ELB SG for National Parks"

  vpc_id = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    X-Contact     = "${var.aws_key_pair_name} <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = ["aws_internet_gateway.default"]
}

////////////////////////////////
// Initial Peer

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20180109*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "initial-peer" {
  connection {
    user        = "${var.aws_image_user}"
    private_key = "${file("${var.aws_key_pair_file}")}"
  }

  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "m4.large"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.default.id}"
  vpc_security_group_ids      = ["${aws_security_group.national-parks.id}"]
  associate_public_ip_address = true

  tags {
    Name          = "${var.aws_key_pair_name}_${random_id.national_parks_id.hex}_initial_peer"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  provisioner "habitat" {
    permanent_peer = true
    use_sudo       = true
    service_type   = "systemd"

    connection {
      host        = "${aws_instance.initial-peer.public_ip}"
      user        = "${var.aws_image_user}"
      private_key = "${file("${var.aws_key_pair_file}")}"
    }
  }
}

////////////////////////////////
// Instances

resource "aws_instance" "np-mongodb" {
  connection {
    user        = "${var.aws_image_user}"
    private_key = "${file("${var.aws_key_pair_file}")}"
  }

  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "m4.large"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.default.id}"
  vpc_security_group_ids      = ["${aws_security_group.national-parks.id}"]
  associate_public_ip_address = true

  tags {
    Name          = "${var.aws_key_pair_name}_${random_id.national_parks_id.hex}_np_mongodb"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  provisioner "habitat" {
    peer         = "${aws_instance.initial-peer.public_ip}"
    use_sudo     = true
    service_type = "systemd"

    service {
      name     = "${var.habitat_origin}/np-mongodb"
      topology = "standalone"
      group    = "${var.group}"
      channel  = "${var.release_channel}"
      strategy = "${var.update_strategy}"
    }

    connection {
      host        = "${aws_instance.np-mongodb.public_ip}"
      user        = "${var.aws_image_user}"
      private_key = "${file("${var.aws_key_pair_file}")}"
    }
  }
}

resource "aws_instance" "national-parks" {
  connection {
    user        = "${var.aws_image_user}"
    private_key = "${file("${var.aws_key_pair_file}")}"
  }

  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "m4.large"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.default.id}"
  vpc_security_group_ids      = ["${aws_security_group.national-parks.id}"]
  associate_public_ip_address = true
  count = 3

  tags {
    Name          = "${var.aws_key_pair_name}_${random_id.national_parks_id.hex}_national_parks"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  provisioner "habitat" {
    peer         = "${aws_instance.initial-peer.public_ip}"
    use_sudo     = true
    service_type = "systemd"

    service {
      binds    = ["database:np-mongodb.${var.group}"]
      name     = "${var.habitat_origin}/national-parks"
      topology = "standalone"
      group    = "${var.group}"
      channel  = "${var.release_channel}"
      strategy = "${var.update_strategy}"
  }

    connection {
      host        = "${self.public_ip}"
      user        = "${var.aws_image_user}"
      private_key = "${file("${var.aws_key_pair_file}")}"
    }
  }
}

////////////////////////////////
// Templates

data "template_file" "initial_peer" {
  template = "${file("${path.module}/../templates/hab-sup.service")}"

  vars {
    flags = "--auto-update --listen-gossip 0.0.0.0:9638 --listen-http 0.0.0.0:9631 --permanent-peer"
  }
}

data "template_file" "sup_service" {
  template = "${file("${path.module}/../templates/hab-sup.service")}"

  vars {
    flags = "--auto-update --peer ${aws_instance.initial-peer.private_ip} --listen-gossip 0.0.0.0:9638 --listen-http 0.0.0.0:9631"
  }
}

data "template_file" "install_hab" {
  template = "${file("${path.module}/../templates/install-hab.sh")}"
}
