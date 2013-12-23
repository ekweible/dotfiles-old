# Colorize output, add file type indicator, and put sizes in human readable format
alias ls='ls -GFh'
alias ll='ls -GFhl'

# other simple aliases
alias cl='clear'
alias g='git'

# DEV ENVIRONMENT
workon_env() {
    cd ~/workspaces/wf/$1/
    if [ ! -z $2 ] 
    then 
        source $2/bin/activate
    fi
}

# DEPLOY
appspot_deploy()
{
    appcfg.py --email=evan.weible@webfilings.com -A ${1:-wf-richapps} -v update . -V ${2:-evan}
}
alias gaedeploy=appspot_deploy

# PULL REQUEST
_git_wfpr ()
{
    local cur=$2
    __gitcomp_nl "$(__git_refs '' $track)"
}
wfpr ()
{
    local br="$(git rev-parse --abbrev-ref HEAD)";
    open -a "/Applications/Google Chrome.app" "https://github.com/evanweible-wf/${1:-web-bones}/pull/new/evanweible-wf:${2:-master}...evanweible-wf:${3:-$br}";
}
complete -o bashdefault -o default -o nospace -F _git_wfpr wfpr 2>/dev/null

alias workspaces="workon_env"

# BIGSKY
alias sky="workon_env evanweible-wf/bigsky ~/dev/wf/sky"
alias skybuild='ant clean-no-flex stage-no-flex'
alias skyrun='python ../runserver.py'
alias skyreset='python tools/erase_reset_data.py --admin=evan.weible@webfilings.com --password=n'
alias skyprune='git remote prune origin && git remote prune codebuilders'

# GRUNT-TEMPLATE-JASMINE-REQUIREJS
alias gtjr="workon_env grunt-template-jasmine-requirejs"

# RICHAPPS
alias ra="workon_env richapps ~/.virtualenvs/richapps"

# WEB-BONES
alias wb="workon_env web-bones"

# WEB-SKIN
alias ws="workon_env web-skin"

# WF-JS-GRUNT
alias wfjsg="workon_env wf-js-grunt"

# WF-JS-VENDOR
alias wfjsv="workon_env wf-js-vendor"

