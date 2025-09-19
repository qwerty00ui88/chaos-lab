resource "aws_lightsail_instance" "this" {
  name              = var.name
  availability_zone = var.availability_zone
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id
  key_pair_name     = var.key_pair_name
  user_data         = var.user_data

  tags = merge(var.tags, {
    Component = "lightsail-instance"
  })
}

resource "aws_lightsail_static_ip" "this" {
  count = var.enable_static_ip ? 1 : 0

  name = "${var.name}-ip"
}

resource "aws_lightsail_static_ip_attachment" "this" {
  count = var.enable_static_ip ? 1 : 0

  static_ip_name = aws_lightsail_static_ip.this[0].name
  instance_name  = aws_lightsail_instance.this.name
}

resource "aws_lightsail_instance_public_ports" "this" {
  instance_name = aws_lightsail_instance.this.name

  dynamic "port_info" {
    for_each = var.public_ports
    content {
      from_port = port_info.value.from
      to_port   = port_info.value.to
      protocol  = port_info.value.protocol
    }
  }
}

output "instance_name" {
  value = aws_lightsail_instance.this.name
}

output "public_ip" {
  value       = var.enable_static_ip ? aws_lightsail_static_ip.this[0].ip_address : aws_lightsail_instance.this.public_ip_address
  description = "Public IP address assigned to the Lightsail dashboard host"
}
