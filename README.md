# Ansible Dotfiles

This repository contains an Ansible playbook for setting up a development environment on a new machine. It installs and configures various tools and dotfiles.

<!--ts-->
* [Ansible Dotfiles](#ansible-dotfiles)
   * [What is this?](#what-is-this)
   * [Requirements](#requirements)
   * [How to use](#how-to-use)
      * [Using <a href="https://github.com/prashantsolanki3/tf-dev-box">Terraform  Development Box</a> companion project](#using-terraform--development-box-companion-project)
      * [Using manual installation](#using-manual-installation)
      * [Run Ansible](#run-ansible)
   * [Credits](#credits)
<!--te-->

## What is this?

This is an Ansible project used to configure and maintain ubuntu based development VM, install software, manage dotfiles, manage the configuration and more.

## Requirements

* Ansible 2.9+
* A Unix-based operating system (e.g. Linux, macOS)

## How to use

### Quick start (macOS or Linux)

```bash
git clone https://github.com/prashantsolanki3/dots.git ~/dots
cd ~/dots

# Dry-run (safe — shows what would change)
make check

# Apply to localhost
make dev
```

All Linux-only roles (`base`, `dev_tools`, `docker`) are gated on
`os_family == Debian` and skip cleanly on macOS. `claude_code`'s global
npm install skips `become` on macOS (global npm typically runs under
nvm there; sudo would break PATH resolution). No flags or overrides
needed.

### Make targets

| Target | Purpose |
|---|---|
| `make check` | Dry-run (`--check --diff`) — no changes applied |
| `make dev` | Apply `dev.yml` to localhost |
| `make scaffold-wiki REPO=<abs-path>` | Scaffold the [LLM-wiki](roles/llm_wiki/) structure into an arbitrary repo |
| `make lint` | Run `ansible-lint` |

### Using [Terraform  Development Box](https://github.com/prashantsolanki3/tf-dev-box) companion project

Clone and Setup Development VM Terraform Repo. Follow the instructions to run the project. It would automatically use this project to create and configure a ubuntu vm on a proxmox host.

### Manual installation (Ubuntu Server, remote)

1. Set up machine with basic installation of Ubuntu Server.
    * SSH server is required if you plan to complete the installation remotely.
2. Move to non-default TTY or SSH into the machine remotely.
3. Install Ansible and other dependencies `sudo apt install python3 python3-pip git`
4. Install Ansible `sudo pip3 install ansible`
5. Clone this repository to `git clone https://github.com/prashantsolanki3/dots.git ~/dots`
6. Change directory: `cd ~/dots`
7. Review the contents of the `dev.yml` file to see what tasks will be performed during the provisioning process. You can also add your own tasks and files by creating a new directory and adding them to the tasks and files directories, respectively.

### Run Ansible manually (legacy)

* Run Ansible in check mode against the legacy `pluto.yml`:

    ```ansible-playbook -i hosts --extra-vars "@env.yml" pluto.yml -C```

* Run Ansible against the hosts defined in the `hosts` file:

    ```ansible-playbook -i hosts --extra-vars "@env.yml" pluto.yml```

    Note: Root privileges required for system-level tasks on Linux (apt
    installs, etc). On macOS, `dev.yml` needs no sudo since Linux-only
    roles skip and the Mac-applicable ones don't touch system state.

    Once the playbooks are applied, you might need to reboot.

## Tokens & secrets

Plugins and MCP servers consume environment variables for auth (GitHub, SonarQube, Telegram, etc.). See [`docs/TOKENS.md`](docs/TOKENS.md) for the full list and where to set them on macOS, Linux, and Docker.

## Credits

* [Addvilz](https://github.com/Addvilz/dots)
