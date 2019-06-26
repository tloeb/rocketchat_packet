# Configure the Packet Provider. 
provider "packet" {
  auth_token = "${var.auth_token}"
}

# Declare your project ID
#
# You can find ID of your project form the URL in the Packet web app.
# For example, if you see your devices listed at
# https://app.packet.net/projects/352000fb2-ee46-4673-93a8-de2c2bdba33b
# .. then 352000fb2-ee46-4673-93a8-de2c2bdba33b is your project ID.
locals {
  project_id = "<UUID_of_your_project>"
}

# If you want to create a fresh project, you can create one with packet_project
# 
# resource "packet_project" "cool_project" {
#   name           = "My First Terraform Project"
# }

# Create a new SSH key
resource "packet_ssh_key" "demokey" {
  name       = "terraform-1"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Create new device with "demokey" included. The device resource "depends_on" the
# key, in order to make sure the key is created before the device.
resource "packet_device" "webserver" {
  hostname         = "web-device"
  plan             = "t1.small.x86"
  facilities       = ["sjc1"]
  operating_system = "ubuntu_16_04"
  billing_cycle    = "hourly"
  project_id       = "${local.project_id}"
  depends_on       = ["packet_ssh_key.demokey"]
  
  provisioner "remote-exec" {
    inline = ["sudo apt -y install python"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${self.access_public_ipv4},' --private-key ${file("~/.ssh/id_rsa")} ansible/rocket_chat.yml" 
  }
}