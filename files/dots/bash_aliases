# Add your bash aliases here in the following format.
# alias <name>="<command>"


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
alias refresh-ansible='ansible-playbook -i localhost dev.yml && source ~/.bashrc'


alias cv='coverage run -m pytest tests & coverage report -m --omit="tests/**"'
alias cv-install='python3 -m pip install coverage'
alias py-venv-activate='. .venv/bin/activate'
alias py-venv-check-and-activate='[[ "$VIRTUAL_ENV" == "" ]]; INVENV=$? && if [ $INVENV != 0 ]; then echo ".venv active"; else echo ".venv not active. Activating .venv" && py-venv-activate; fi'
alias py-venv-install-app-and-test='python3 -m pip install -r requirements.txt && python3 -m pip install -r tests/requirements.txt'
alias py-venv-refresh='deactivate && rm -rf .venv && python3 -m venv .venv && py-venv-check-and-activate && py-venv-install-app-and-test && cv-install'