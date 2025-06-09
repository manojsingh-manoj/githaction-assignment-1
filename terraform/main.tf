# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.rg_name}-${var.environment}"
  location = var.location
}


# Create a virtual network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a subnet
resource "azurerm_subnet" "main" {
  name                 = "subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP
resource "azurerm_public_ip" "main" {
  name                = "pip-vm-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# Create a network security group
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}


# Create NSG rules for open ports
resource "azurerm_network_security_rule" "open_ports" {
  for_each                    = toset([for port in var.open_ports : tostring(port)])
  name                        = "allow-port-${each.key}"
  priority                    = 100 + index(var.open_ports, tonumber(each.key))
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.key
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Create a network interface
resource "azurerm_network_interface" "main" {
  name                = "nic-vm-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Associate NSG with network interface
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Create the Linux VM
resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-assignment-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = "adminuser"
  #admin_password                  = "Adminuser@1234567"
  #disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username = "adminuser"
    #public_key = file("~/.ssh/id_rsa.pub") # Ensure this file exists or replace with your SSH public key
    public_key = file("${path.module}/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Install Docker using custom_data
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io
              systemctl start docker
              systemctl enable docker
              # Add the user to the docker group to allow running docker without sudo
              usermod -aG docker adminuser
              EOF
  )
}