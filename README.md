# .dots

Dotfiles with Ansible!

## What is this?

This is an Ansible project used to configure and maintain ubuntu based development VM, install software, manage dotfiles, manage the configuration and more.

## How to use

### Using Terraform

- Clone and Setup Development VM Terraform Repo. Follow the instructions to run the project. It would automatically use this project to create and configure a ubuntu vm on a proxmox host.

### Using manual installation

1. Set up machine with basic installation of Ubuntu Server.
    - SSH server is required if you plan to complete the installation remotely.
2. Move to non-default TTY or SSH into the machine remotely.
3. Install Ansible and other dependencies `sudo apt install python3 python3-pip git`
4. Install Ansible `sudo pip3 install ansible`
5. Clone this repository to `~/dots/`.
6. Edit `dev.yml` as required.

`ansible-playbook -i hosts dev.yml -K -C` to run Ansible in check mode.
`ansible-playbook -i hosts dev.yml -K` to run Ansible against the host defined in the `hosts` file.

Root privileges required to install system packages and other configuration. 
Ansible will ask you for your password to become root user.
This is required because Ansible automates package installation, changes settings only accessible to root etc.

Once the playbooks are applied, you might need to reboot.

### Credits
- [Addvilz](https://github.com/Addvilz/dots)