# 🚀 Terraform Libvirt K3s Cluster

Welcome to the Terraform Libvirt K3s Cluster project! This Terraform project automates the creation of a K3s cluster using Libvirt. It provisions a control node and multiple worker nodes on a Libvirt-based virtualization environment. The nodes are based on Ubuntu Jammy cloud images and are configured with static IP addresses.

## 📚 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Structure](#project-structure)
3. [Usage](#usage)
4. [Using with Ansible](#using-with-ansible)
5. [Variables](#variables)
6. [Modules](#modules)
   - [Base Image](#base-image)
   - [Control Node](#control-node)
   - [Worker Nodes](#worker-nodes)
7. [Outputs](#outputs)
8. [License](#license)

---

## 🛠️ Prerequisites

Before diving in, make sure you have the following:

1. **Terraform**: Install Terraform from [here](https://www.terraform.io/downloads.html).
2. **Libvirt**: Ensure Libvirt is installed and running on your system.
3. **SSH Key**: An SSH key pair for accessing the nodes. By default, the public key is expected at `~/.ssh/id_ed25519.pub`.
4. **QEMU/KVM**: Ensure QEMU/KVM is installed and configured.

## 🗂️ Project Structure

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

## 🚀 Usage

Ready to get started? Follow these steps:

1. Clone this repository and navigate into it:
   ```
   git clone https://github.com/yourusername/terraform-libvirt-k3s.git
   cd terraform-libvirt-k3s
   ```

2. Initialize Terraform:
   ```
   terraform init 
   ```

3. Roll out the infrastructure:
   ```
   terraform apply 
   ```

4. To destroy the infrastructure when you're done:
   ```
   terraform destroy 
   ```

---

## 🤝 Using with Ansible

To use this project together with Ansible for setting up a K3s, Rancher, and VictoriaMetrics cluster, follow these steps:

1. After rolling out the infrastructure with Terraform, clone the Ansible repository:
   ```
   git clone https://github.com/abaas-madscience/ansible-k3-rancher.git
   cd ansible-k3-rancher
   ```

2. Update the Ansible inventory file with the IP addresses of the nodes created by Terraform.

3. Run the Ansible playbooks to configure K3s, Rancher, and VictoriaMetrics:
   ```
   ansible-playbook -i inventory.ini site.yml
   ```

For more details, refer to the [Ansible K3s Rancher repository](https://github.com/abaas-madscience/ansible-k3-rancher).

---

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Happy Terraforming! 🌍

