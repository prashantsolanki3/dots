# Add your bash aliases here in the following format.
# alias <name>="<command>"

# System Aliases
alias ls='ls -CHG --color'
alias mkdir='mkdir -pv'
alias f='find . |grep '
alias h='history|grep '
alias gc='git commit -m'
alias la='ls -ahG'
alias ll='ls -ahlG'

# if user is not root, pass all commands via sudo #
if [ $UID -ne 0 ]; then
    alias reboot='sudo reboot'
    alias update='sudo apt-get update && sudo apt-get upgrade'
fi

alias diff='colordiff'
# Ansible aliases
#alias refresh-ansible='ansible-playbook -i localhost dev.yml && source ~/.bashrc'

# Python aliases
alias python310='python3.10'
alias cv='coverage run -m pytest tests && coverage report -m --omit="tests/**"'
alias cv-install='python310 -m pip install coverage'
alias py-venv-create='python310 -m venv .venv'
alias py-venv-activate='. .venv/bin/activate'
alias py-venv-check-and-activate='[[ "$VIRTUAL_ENV" == "" ]]; INVENV=$? && if [ $INVENV != 0 ]; then echo ".venv active"; else echo ".venv not active. Activating .venv" && py-venv-activate; fi'
alias py-venv-install-app-and-test='py-venv-check-and-activate && python310 -m pip install -r requirements.txt && python310 -m pip install -r tests/requirements.txt'
alias py-venv-refresh='deactivate && rm -rf .venv && python310 -m venv .venv && py-venv-install-app-and-test && cv-install'

# Jekyll aliases
alias jekyllserve='docker run --volume="$PWD:/srv/jekyll:Z" -p 4000:4000 -it jekyll/jekyll jekyll serve'