#### INSTANCE HTTP ####

# Create instance
#
resource "openstack_compute_instance_v2" "instance_http" {
  count              = "${var.desired_capacity_http}"
  name               = "http-${count.index}"
  image_name         = "${var.image}"
  flavor_name        = "${var.flavor_http}"
  key_pair           = "${openstack_compute_keypair_v2.user_key.name}"
  user_data          = "${file("scripts/first-boot.sh")}"
  network {
    port             = "${element(openstack_networking_port_v2.port_instance_http.*.id, count.index)}"
  }
}

# Create network port
resource "openstack_networking_port_v2" "port_instance_http" {
  count              = "${var.desired_capacity_http}"
  name               = "port-http-${count.index}"
  network_id         = "${openstack_networking_network_v2.network_http.id}"
  admin_state_up     = true
  security_group_ids = ["${openstack_compute_secgroup_v2.security_group_ssh.id}",
                        "${openstack_compute_secgroup_v2.security_group_http.id}"]
  fixed_ip           = {
    subnet_id        = "${openstack_networking_subnet_v2.subnet_http.id}"
  }
}

# Create floating ip
resource "openstack_networking_floatingip_v2" "floating_http" {
  count              = "${var.desired_capacity_http}"
  pool               = "${var.external_network}"
}

# Attach floating ip to instance
resource "openstack_compute_floatingip_associate_v2" "floating_http" {
  count              = "${var.desired_capacity_http}"
  floating_ip        = "${element(openstack_networking_floatingip_v2.floating_http.*.address, count.index)}"
  instance_id        = "${element(openstack_compute_instance_v2.instance_http.*.id, count.index)}"
}
