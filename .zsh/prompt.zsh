#===============================================================================
#
#          FILE: .zsh_prompt
#
#         USAGE: Sourced automatically in .zshrc
#
#   DESCRIPTION: In my opinion which I respect very much this may be one of the
#                best zsh prompts on the planet.
#
#===============================================================================

autoload -U colors && colors
autoload -U promptinit
autoload -Uz vcs_info

# Make the colors easier to reference
local reset white gray green red yellow blue cyan magenta black
reset="%{${reset_color}%}"
white="%{$fg[white]%}"
gray="%{$fg_bold[black]%}"
green="%{$fg_bold[green]%}"
red="%{$fg[red]%}"
yellow="%{$fg[yellow]%}"
cyan="%{$fg[cyan]%}"
blue="%{$fg[blue]%}"
magenta="%{$fg[magenta]%}"
black="%{$fg[black]%}"


local -A pr_com            # Associative array
local -a prompt_left_lines # Array parameters


zstyle ":pr_jrock:" mode full
zstyle ':pr_jrock:*' hooks pwd usr vcs venv npm jobs prompt
zstyle ':pr_jrock:*' pwd "%~"

# Set vcs_info options
zstyle ':vcs_info:*' enable git                                           # We are only concerned with git VCS, so enable it
zstyle ':vcs_info:(git*):*' check-for-changes true                        # We want to monitor changes to the repository's
# Format of what we will display for the git repo information.
# %s - The VCS in use (git, hg, svn, etc.).
# %i - The current revision number or identifier. (SHA we only display 10 chars)
# %c - The string from the stagedstr style if there are staged changes in the repository.
# %u - The number of unapplied patches (unapplied-string).
# %b - Information about the current branch.
# %m - A "misc" replacement. It is at the discretion of the backend to decide what this replacement expands to.
#      It is currently used by the hg and git backends to display patch information from the mq and stgit extensions.
# Format of what we will display during a special action on the repo (Ex. Interactive rebase or merge conflict)
zstyle ':vcs_info:(git*)' actionformats "(%b|${red}%a${reset}%m)"
zstyle ':vcs_info:(git*)' formats "(%b%m)"
zstyle ':vcs_info:git*+set-message:*' hooks git-statuses git-st

# Run all the prompt hook functions
# (stolen, wholesale, from the excellent hook system in vcs_info)
function pr_run_hooks() {
    local hook func
    local -a hooks

    zstyle -g hooks ":pr_jrock:*" hooks

    (( ${#hooks} == 0 )) && return 0

    for hook in ${hooks} ; do
        func="+pr-${hook}"
        if (( ${+functions[$func]} == 0 )); then
            continue
        fi
        true
        ${func} "$@"
        case $? in
            (0)
                ;;
            (*)
                break
                ;;
        esac
    done
}

# This is our prompt, this is a compressed example it will expand
# to the width of the console
# ┌──(~/src/dotfiles)v(dotfiles)──────(✔)─
# ├──(master [origin/master ] Unstaged)
# └───>
function +pr-mode-full() {
    local i info_line_width return_status_width filler venv_shim npm_shim

    infoline=( ${pr_com[pwd]} ${pr_com[usr]} )

    # If we are in a directory that has a node_modules subdirectory we want to
    # display that on the info line
     [[ -n ${pr_com[npm]} ]] && infoline[1]=(
         ${infoline[1]}
         "${cyan} n${reset}(${pr_com[npm]}${reset})${reset}"
     )

    # The prompt was not taking up the full width of the terminal when displaying npm info
    # So if we are in a npm directory then we add a one character shim to the width of the filler
     npm_shim=0
     if [[ -n ${pr_com[npm]} ]]; then
         npm_shim+=1
     fi

    # If we are in a virtualenv we want to display that on the info line
    [[ -n ${pr_com[venv]} ]] && infoline[1]=(
        ${infoline[1]}
        "${reset}(${blue}${gray}${pr_com[venv]}${reset})${reset}"
    )

    # The prompt was not taking up the full width of the terminal when in a virtualenv
    # If we are in a virtualenv then we add a one character shim to the width of the filler
    venv_shim=0
    if [[ -n ${pr_com[venv]} ]]; then
        venv_shim+=1 # Shim the filler to take up the entire width of the prompt
    fi

    # Full-width filler; search/replace color wraps to find real text width
    info_line_width=${(S)infoline//\%\{*\%\}} # search-and-replace color escapes
    info_line_width=${#${(%)info_line_width}} # expand all escapes and count the chars
    return_status_width=3 # We will take up three spaces to display the return code (✔)

    # Set the text string that will be used to fill the width of the terminal filler
    filler="${reset}${(l:$(( $COLUMNS - $info_line_width - $return_status_width + $venv_shim + $npm_shim))::─:)}${reset}"
    infoline[-1]=( ${filler} ${infoline[-1]} )

    # --------------------------
    # Assemble the prompt lines
    # --------------------------
    # Default we will always have a info line and a prompt line
    lines=(
        ${(j::)infoline}
        ${pr_com[prompt]}
    )

    # If we are in a git repo we will have three lines info, git_info, prompt
    [[ -n ${pr_com[vcs]} ]] && lines[1]=(
        ${lines[1]}
        "${reset}${pr_com[vcs]}${reset}"

    )

    # Add some connecting lines to the beginning of our prompts
    if [[ -n ${pr_com[vcs]} ]]; then
        lines[1]="${reset}┌──${lines[1]}${reset}─${reset}"
        lines[2]="${reset}├──${lines[2]}${reset}"
        lines[3]="${reset}└──➤${lines[3]}${reset}"
    else
        lines[1]="${reset}┌──${lines[1]}${reset}─${reset}"
        lines[2]="${reset}└──➤${lines[2]}${reset}"
    fi

    # And we set the value for the prompt_left_lines
    prompt_left_lines=( ${lines[@]} )
}


# Show info collected from vcs_info
function +pr-vcs() {
    local -a v_vcs

    [[ -n ${vcs_info_msg_0_} ]] && v_vcs=(
        ${reset}
        ${vcs_info_msg_0_}
        ${reset}
    )

    pr_com[vcs]=${(j::)v_vcs}
}

# Show virtualenv information
 function +pr-venv() {
    local -a v_venv

    [[ -n ${VIRTUAL_ENV} ]] && v_venv=(
        ${blue}
        $(basename ${VIRTUAL_ENV})
        ${reset}
    )

    pr_com[venv]=${(j::)v_venv}
}

# Show npm information
#function +pr-npm() {
#    local -a v_npm
#
#    if [[ ${NODE_NAME}  != "" ]]; then
#        v_npm=(
#            ${cyan}
#            ${NODE_NAME}
#            ${reset}
#        )
#    fi
#
#    pr_com[npm]=${(j::)v_npm}
#}

# Show number of background jobs, or hide if none
function +pr-jobs() {
    local -a v_jobs
    v_jobs=( "%(1j.${reset}%j${reset}.)" )
    pr_com[jobs]=${(j::)v_jobs}
}

function +pr-prompt() {
    local -a v_pwd i_pwd
    local -a exit_status i_usr i_host exit_status

    # Add the print working directory logic
    zstyle -g i_pwd ":pr_jrock:*" pwd
    v_pwd+=( ${reset}\( )
    [[ -w $PWD ]] && v_pwd+=( ${reset} ) || v_pwd+=( ${yellow} )
    v_pwd+=( ${i_pwd} )
    v_pwd+=( ${reset}\) )
    v_pwd+=( ${reset} )
    pr_com[pwd]=${(j::)v_pwd}${reset}


    # Add exit status check or x logic
    exit_status=( ${reset}\( )
    exit_status+="%(0?.${green}✔.${red}✘)"
    exit_status+=( ${reset}\) )
    exit_status+=( ${reset} )

    pr_com[usr]=${(j::)exit_status}
}

# vcs_info functions ##########################################################

# Show remote ref name and number of commits ahead-of or behind
function +vi-git-st() {
    local ahead behind remote
    local -a gitstatus

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name --abbrev-ref 2>/dev/null)}

    if [[ -n ${remote} ]] ; then
        ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | sed -e 's/^[ \t]*//')
        (( $ahead )) && gitstatus+=( "${green}+${ahead}${reset}" )

        behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | sed -e 's/^[ \t]*//')
        (( $behind )) && gitstatus+=( "${red}-${behind}${reset}" )

        user_data[gitstatus]=${gitstatus}
        hook_com[branch]="${hook_com[branch]} [${remote} ${(j:/:)gitstatus}]"
    fi
}

# Show the above/behind upstream counts more tersely for the compact display
function +vi-git-st-compact() {
    [[ -n ${user_data[gitstatus]} ]] \
        && hook_com[misc]="@{u}${(j:/:)user_data[gitstatus]}"
}

function +vi-git-statuses() {
    git status -s >| /tmp/gitstatus.txt
    staged=$( cat /tmp/gitstatus.txt | grep -c "^[MARCD]")
    unstaged=$( cat /tmp/gitstatus.txt | grep -c "^.[MARCD]")
    untracked=$( cat /tmp/gitstatus.txt | grep -c "^\?")
    stashes=$(git stash list 2>/dev/null | wc -l | sed -e 's/^[ \t]*//')

    if [[ ${staged} != 0 ]] ; then
        hook_com[misc]+=" ${green}${staged}${reset}"
    fi

    if [[ ${unstaged} != 0 ]] ; then
        hook_com[misc]+=" ${red}${unstaged}${reset}"
    fi

    if [[ ${untracked} != 0 ]] ; then
        hook_com[misc]+=" ${yellow}${untracked}${reset}"
    fi

    if [[ ${stashes} != 0 ]] ; then
        hook_com[misc]+=" ${gray}${stashes}${reset}"
    fi
}


# --------------------------
# Finally we execute the above prompt functions
# --------------------------

# To be added to the precmd_* array so it is executed before each prompt
function precmd_prompt {
    local func

    # Clear out old values
    pr_com=()
    prompt_left_lines=()

    # Collect needed data
    vcs_info
    pr_run_hooks

    # Use the above data and build the prompt arrays
    func="+pr-mode-full"
    ${func} "$@"

    # Set the prompts
    PROMPT="${(F)prompt_left_lines} "
}


# Precmd functions <<1
#------------------------------------------------------------------------------
# Run precmd functions so we get our pimped out prompt
#------------------------------------------------------------------------------
precmd_functions=( precmd_prompt )



#function git_prompt_info {
#  local ref=$(git symbolic-ref HEAD 2> /dev/null)
#  local gitst="$(git status 2> /dev/null)"
#  local pairname=${${${GIT_AUTHOR_EMAIL#pair+}%@github.com}//+/\/}
#  if [[ ${pairname} == 'ch' || ${pairname} == '' ]]; then
#    pairname=''
#  else
#    pairname=" ($pairname)"
#  fi
#
#  if [[ -f .git/MERGE_HEAD ]]; then
#    if [[ ${gitst} =~ "unmerged" ]]; then
#      gitstatus=" %{$fg[red]%}unmerged%{$reset_color%}"
#    else
#      gitstatus=" %{$fg[green]%}merged%{$reset_color%}"
#    fi
#  elif [[ ${gitst} =~ "Changes to be committed" ]]; then
#    gitstatus=" %{$fg[blue]%}!%{$reset_color%}"
#  elif [[ ${gitst} =~ "use \"git add" ]]; then
#    gitstatus=" %{$fg[red]%}!%{$reset_color%}"
#  elif [[ -n `git checkout HEAD 2> /dev/null | grep ahead` ]]; then
#    gitstatus=" %{$fg[yellow]%}*%{$reset_color%}"
#  else
#    gitstatus=''
#  fi
#
#  if [[ -n $ref ]]; then
#    echo "%{$fg_bold[green]%}/${ref#refs/heads/}%{$reset_color%}$gitstatus$pairname"
#  fi
#}
#
#PROMPT='%~%<< $(git_prompt_info)${PR_BOLD_WHITE}>%{${reset_color}%} '
#
