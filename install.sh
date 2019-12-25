#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "always            : full path to project what must to be initialized with 'MakeMeBetter'."
    echo "-h|--help         : print this message."
    echo "-a|--aliases      : only install aliases for 'MakeMeBetter' Makefile."
    echo "-l|--library      : use for initialize only specified library."
    echo "-s|--skip         : skip cloning 'MakeMeBetter' to specified folder."
    exit
fi

function set_project_data {
    if [ -z "$1" ]; then
        echo "missed path to folder. (-h for help)"
        exit
    fi
    project_path=$1
    project_name=$(basename -- $project_path)
}

list_cloned_repos=

function git_clone {
    echo "Cloning '$1' to -> '$3':"
    git clone --recurse-submodules $2 $4
    if [ -d "./$4" ]; then
        mkdir -p $3
        cp -rf $4/* $3/
        list_cloned_repos+="$4 "
        return 1
    fi
    return 0
}

function lib_init {
    if [ ! -d "./mmb_temp" ]; then
        git clone https://github.com/Iipal/makemebetter ./mmb_temp
    fi
    if [ -d "$1/configs" ]; then
        rm -rf $1/configs/*
    else
        mkdir -p "$1/configs"
    fi
    cp -rfv ./mmb_temp/libs/_example/configs/* $1/configs/
    cp -rfv ./mmb_temp/libs/_example/Makefile $1/Makefile
    echo ""
    echo "/--------------------------------------------------------------------"
    echo "| '$2' library succesfully initialized via 'MakeMeBetter'"
    echo "\--------------------------------------------------------------------"
    echo ""
}

function install_aliases {
    echo "
# MakeMeBetter aliases:
alias debug='make debug'
alias debugr='make debug_all'

alias sanitize='make sanitize'
alias sanitizer='make sanitize_all'

alias assembly='make assembly'
alias assemblyr='make assembly_all'

alias dassembly='make debug_assembly'
alias dassemblyr='make debug_assembly_all'

alias pedantic='make pedantic'
alias pedanticr='make pedantic_all'

alias fclean='make fclean'
alias clean='make clean'
alias pre='make pre'
alias re='make re'
" > ~/.mmb_aliases
    src_mmb=$(grep "source ~/.mmb_aliases" ~/.zshrc)
    if [ -z "$src_mmb" ]; then
        echo "source ~/.mmb_aliases" >> ~/.zshrc
    fi
    echo " - 'MakeMeBetter' aliases succesfully installed. For more info look at ~/.mmb_aliases."
    exit
}

if [ "$1" == "-s" ] || [ "$1" == "--skip" ]; then
    set_project_data $2
elif [ "$1" == "-a" ] || [ "$1" == "--aliases" ]; then
    install_aliases
elif [ "$1" == "-l" ] || [ "$1" == "--library" ]; then
    set_project_data $2
    lib_init $project_path $project_name
    rm -rf ./mmb_temp
    exit
else
    set_project_data $1
    git_clone MakeMeBetter https://github.com/Iipal/makemebetter $project_path ./mmb_temp
    rm -rf $project_path/libs/_example
fi

clear
echo -e " Additional configuration for \e[1m'$project_name'\e[0m:"

function at_exit {
    rm -rf $list_cloned_repos
    rm -rf $project_path/libs/_example
    exit
}

function help_message {
    echo ""
    echo -e "/-----------------------------------------------------------------"
    echo -e "| \e[36ml\e[39m: List anything inside the '$project_path'           \e[2m| name\e[0m"
    echo -e "| \e[35ma\e[39m: Add sub-project\library to -> '$project_path/libs' \e[2m| url, name\e[0m"
    echo -e "| \e[31mr\e[39m: Remove library from '$project_path/libs'           \e[2m| name\e[0m"
    echo -e "| \e[31md\e[39m: Delete '$project_path' and quit                    \e[2m| Y/n\e[0m"
    echo -e "| \e[34mh\e[39m: Print this help message"
    echo -e "| q: quit"
    echo -e "\-----------------------------------------------------------------"
    echo ""
}

function add_sub_project {
    subp_url=$1
    if [ -z "$subp_url" ]; then
        read -p " | Sub-project github link: " subp_url
        if [ -z "$subp_url" ]; then
            echo " ! link can't be empty !"
            return 0
        fi
    fi

    subp_name=$2
    if [ -z "$subp_name" ]; then
        read -p " | Sub-project custom folder name: " subp_name
        if [ -z "$subp_name" ]; then
            subp_name=${subp_url##*/}
            subp_name=${subp_name%%.git}
        fi
    fi

    git_clone $subp_name $subp_url $project_path/libs/$subp_name ./$subp_name
    if [ "$?" == "0" ]; then
        return 0
    fi

    echo ""
    read -p " | Switch to specified branch?(Y/n)" is_branch_switch
    if [ "$is_branch_switch" == "y" ] || [ "$is_branch_switch" == "Y" ]; then
        git --no-pager -C ./$subp_name branch --remotes
        read -p "Choose branch(empty to discard):" subp_branch
        if [ ! -z "$subp_branch" ]; then
            git -C ./$subp_name checkout $subp_branch
            cp -rf ./$subp_name/* $project_path/libs/$subp_name/
        fi
    fi

    read -p " | Initialize this sub-project via 'MakeMeBetter'?(Y/n) " is_mmb_init
    if [ "$is_mmb_init" == "y" ] || [ "$is_mmb_init" == "Y" ]; then
        lib_init $project_path/libs/$subp_name $subp_name
    fi
    echo "/ Done."
}

function list_dir {
    list_path=$1
    if [ -z "$list_path" ]; then
        ls -1 "$project_path/"
        read -p " | List: $project_path/" list_path
    fi

    ls -lah "$project_path/$list_path"
}

function remove_lib {
    r_lib=$1
    if [ -z "$r_lib" ]; then
        echo "$project_path/libs:"
        ls -1 "$project_path/libs"
        read -p " | Remove: $project_path/libs/" r_lib
    fi

    if [ -z "$r_lib" ]; then
        return 0
    elif [ -d "$project_path/libs/$r_lib" ]; then
        rm -rf "$project_path/libs/$r_lib"
        echo " | $project_path/libs/$r_lib removed."
    else
        echo " | $project_path/libs/$r_lib not founded."
    fi

}

function remove_path {
    answer=$1
    if [ -z "$answer" ]; then
        read -p " ? Sure you want to delete whole $project_path folder ?(Y/n): " answer
    fi

    if [ "$answer" == "y" ] || [ "$answer" == "Y" ] ; then
        rm -rf $project_path
        at_exit
    fi
}

help_message
while : ; do
    read -p "|> " opt arg1 arg2
    case "$opt" in
        "q")
            at_exit
            ;;
        "h")
            help_message
            ;;
        "a")
            add_sub_project $arg1 $arg2
            ;;
        "l")
            list_dir $arg1
            ;;
        "r")
            remove_lib $arg1
            ;;
        "d")
            remove_path $arg1
            ;;
        *)
            echo "_ Invalid option."
            ;;
    esac
    echo ""
done
