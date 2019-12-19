#!/bin/bash

if [ -z "$1" ]; then
    echo "missed path to folder. (-h for help)"
    exit
fi

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "1 argument : full path to project what must to be initialized with 'MakeMeBetter'."
    echo "-h         : print this message."
    exit
fi

function git_clone {
    echo "Cloning '$1' to -> '$3':"
    git clone --recurse-submodules $2 cloning_temp_folder
    if [ -d "./cloning_temp_folder" ]; then
        mkdir -p $3
        cp -rf cloning_temp_folder/* $3/
        rm -rf cloning_temp_folder
        return 1
    fi
    return 0
}

project_path=$1
project_name=$(basename -- $project_path)

mkdir -p $project_path

git_clone MakeMeBetter https://github.com/Iipal/makemebetter $project_path

clear
echo ""
echo " Additional configuration for '$project_name':"
echo ""

function at_exit {
    rm -rf $project_path/libs/_example
    exit
}

function help_message {
    echo "l: List anything inside the '$project_path'.           | name"
    echo "a: Add sub-project\library to -> '$project_path/libs'. | url, name"
    echo "r: Remove library from '$project_path/libs'.           | name"
    echo "d: Delete '$project_path' and quit.                    | Y/n"
    echo "h: Print this help message."
    echo "q: quit."
}

function add_sub_project {
    subp_url=$1
    if [ -z "$subp_url" ]; then
        read -p "Sub-project github link: " subp_url
        if [ -z "$subp_url" ]; then
            echo "link can't be empty!"
            return 0
        fi
    fi

    subp_name=$2
    if [ -z "$subp_name" ]; then
        read -p "Sub-project custom folder name: " subp_name
        if [ -z "$subp_name" ]; then
            subp_name=${subp_url##*/}
            subp_name=${subp_name%%.git}
        fi
    fi

    git_clone $subp_name $subp_url $project_path/libs/$subp_name
    if [ "$?" == "0" ]; then
        return 0
    fi

    echo ""
    read -p "Initialize this sub-project with 'MakeMeBetter'?(Y/n): " is_customize
    if [ "$is_customize" == "y" ] || [ "$is_customize" == "Y" ]; then
        mkdir -p "$project_path/libs/$subp_name/configs"
        cp -rf $project_path/libs/_example/Makefile $project_path/libs/$subp_name/Makefile
        cp -rf $project_path/libs/_example/configs/* $project_path/libs/$subp_name/configs/
    fi
    echo "Done."
}

function list_dir {
    list_path=$1
    if [ -z "$list_path" ]; then
        ls -1 "$project_path/"
        read -p "List: $project_path/" list_path
    fi

    ls -lah "$project_path/$list_path"
}

function remove_lib {
    r_lib=$1
    if [ -z "$r_lib" ]; then
        echo "$project_path/libs:"
        ls -1 "$project_path/libs"
        read -p "Remove: $project_path/libs/" r_lib
    fi

    if [ -z "$r_lib" ]; then
        return 0
    elif [ -d "$project_path/libs/$r_lib" ]; then
        if [ "${r_lib##*/}" == "_example" ]; then
            echo "** Do not delete '$project_path/libs/_example'. It's will be deleted by me at exit. **"
        else
            rm -rf "$project_path/libs/$r_lib"
            echo "$project_path/libs/$r_lib removed."
        fi
    else
        echo "$project_path/libs/$r_lib not founded."
    fi

}

function remove_path {
    answer=$1
    if [ -z "$answer" ]; then
        read -p "Sure you want to delete whole $project_path folder ?(Y/n): " answer
    fi

    if [ "$answer" == "y" ] || [ "$answer" == "Y" ] ; then
        rm -rf $project_path
        at_exit
    fi
}

help_message
while : ; do
    read -p "$> " opt arg1 arg2
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
            echo "Invalid option."
            ;;
    esac
    echo ""
done
