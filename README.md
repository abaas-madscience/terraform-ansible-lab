# Terraform Libvirt K3s Cluster

This Terraform project automates the creation of a K3s cluster using Libvirt. It provisions a control node and multiple worker nodes on a Libvirt-based virtualization environment. The nodes are based on Ubuntu Jammy cloud images and are configured with static IP addresses.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Structure](#project-structure)
3. [Usage](#usage)
4. [Variables](#variables)
5. [Modules](#modules)
   - [Base Image](#base-image)
   - [Control Node](#control-node)
   - [Worker Nodes](#worker-nodes)
6. [Outputs](#outputs)
7. [License](#license)

---

## Prerequisites

Before using this Terraform configuration, ensure you have the following:

1. **Terraform**: Install Terraform from [here](https://www.terraform.io/downloads.html).
2. **Libvirt**: Ensure Libvirt is installed and running on your system.
3. **SSH Key**: An SSH key pair for accessing the nodes. By default, the public key is expected at `~/.ssh/id_ed25519.pub`.
4. **QEMU/KVM**: Ensure QEMU/KVM is installed and configured.

## Project Structure

```
The project is organized as follows:
.
├── main.tf         # Main Terraform configuration
├── variables.tf    # Input variables
├── outputs.tf      # Output values
├── README.md       # This file
├── modules/        # Reusable Terraform modules
│   ├── base_image/ # Module to download and manage the base image
│   ├── control_node/ # Module to create the control node
│   └── worker_node/ # Module to create worker nodes
```

---

## Usage

Clone this repository and cd into it:
 ```
   cd terraform-libvirt-k3s
```

Initialize Terraform:
```
terraform init 
```

Roll out:
```
terraform apply 
```

To destroy the infrastructure:
```
terraform destroy 
```

