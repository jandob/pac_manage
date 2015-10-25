#!/bin/env bash

# global vars
LIST_FILE="~/package-list"
NO_CONFIRM=""

redrawProgressBar() { # int barsize, int base, int i, int top
    local barsize=$1
    local base=$2
    local current=$3
    local top=$4
    local j=0
    local progress=$(( ($barsize * ( $current - $base )) / ($top - $base ) ))
    echo -n "["
    for ((j=0; j < $progress; j++)); do
        echo -n '='
    done
    echo -n '=>'
    for ((j=$progress; j < $barsize ; j++)); do
        echo -n ' '
    done
    echo -n "] $(( $current )) / $top " $'\r'
}
addSection() {
    local list=$1
    local section=$2
    local comment=$3
    if [ -z "$comment" ]; then
        echo "${section}=(" >> $LIST_FILE
    else
        echo "${section}=( # $comment" >> $LIST_FILE
    fi
    for val in $list; do
        echo $val >> $LIST_FILE
    done
    echo ")" >> $LIST_FILE
}
createInitialPackageList() {
    # write package-list
    echo "# package-list for $0" > $LIST_FILE
    addSection "" "NEW_PACKAGES" "new packages will be added here"
    addSection "$(pacman -Qqen)" "NATIVE_PACKAGES"
    addSection "$(yaourt -Qma | grep -v ^local | cut -d' ' -f1 | cut -d/ -f2)"\
        "AUR_PACKAGES"
    addSection "$(yaourt -Qma | grep ^local | cut -d' ' -f1 | cut -d/ -f2)"\
        "LOCAL_PACKAGES" "true local packages, not from aur"
    echo " # vim: foldmethod=marker foldmarker=\=(,):" >> $LIST_FILE
}
updatePackageList() {
    for package in $(yaourt -Qqe); do
        if ! grep --quiet $package $LIST_FILE; then
            echo adding $package
            local repository=$(yaourt -Qe $package | cut -d' ' -f1 | cut -d/ -f1)
            sed -i "/NEW_PACKAGES=(/a $package # $repository" $LIST_FILE
        fi
    done
}
filterList() {
    local comments='/^\s*#.*/d'
    local syntax='/=(\|)/d'
    for key in $(sed "$comments" $LIST_FILE | sed "$syntax"); do
        echo $key
    done
}
installMissing() {
    local list=($(filterList))
    for i in "${!list[@]}"; do
        local package="${list[i]}"
        if ! (yaourt -Qq $package > /dev/null); then
            yaourt -S --needed $NO_CONFIRM $package
        fi
        redrawProgressBar 50 0 $i ${#list[@]}
    done
    echo ""
}
removePackages() {
    for package in $(pacman -Qqe); do
        if ! (grep --quiet $package $LIST_FILE); then
            echo "removing $package"
            sudo pacman -Rns $NO_CONFIRM $package
        fi
    done
}
function printHelpMessage() {
    cat << EOF
$0 manages your packages in a single file where you can add comments
and group your packages.

    USAGE: $0 [OPTIONS] OPERATION

    Available OPERATIONs:
        install
            Install all missing packages.

        update
            Update the package list. (New packages are added to the section
            'NEW_PACKAGES')

        remove
            Removes all packages that are installed but not in the
            package-list.

    If multiple operations are given they are carried out in the order:
        1. remove
        2. update
        3. install

    OPTIONS:
    -h --help
        Shows this help message.

    -l --list FILE_NAME
        Set the package-list file name. If the file does not exist it is
        created. (Default: '~/package-list')

    -n --no-confirm
        Don't ask for confirmations. Applys to remove and install operations.


    USE CASES / EXAMPLES:
        # generate an initial package-list
        >>> $0
        # edit the list to your likings (add comments, reorder entries etc.)
        >>> vim ~/package-list
        # install new packages to your system
        # decide you want to keep them
        # save them to your package-list (1)
        >>> $0 update
        # install some packages
        >>> sudo pacman -S cowsay ponysay
        # test the installed applications and decide you dont want to keep them
        # remove them (restore the state from (1))
        >>> $0 remove
EOF
}
commandLineInterface() {
    while true; do
        case "$1" in
            -h|--help)
                shift
                printHelpMessage "$0"
                exit 0
                ;;
            -l|--list)
                shift
                LIST_FILE="$1"
                shift
                ;;
            -n|--no-confirm)
                shift
                NO_CONFIRM="--noconfirm"
                ;;
            update)
                shift
                local do_update=1
                ;;
            install)
                shift
                local do_install=1
                ;;
            remove)
                shift
                local do_remove=1
                ;;
            '')
                shift
                break
                ;;
            *)
                echo "unsupported argument: $1"
                exit 1
                shift
        esac
    done
    LIST_FILE="${LIST_FILE/#\~/$HOME}" # expand ~
    if ! [ -f "$LIST_FILE" ]; then
        echo "creating initial package list: '$LIST_FILE'"
        createInitialPackageList
    else
        if [ -z "$do_remove" ] && [ -z "$do_update" ] && [ -z "$do_install" ]; then
            printHelpMessage "$0"
            exit 1
        fi
    fi
    if [ -n "$do_remove" ]; then
        echo "removing packages..."
        removePackages
    fi
    if [ -n "$do_update" ]; then
        echo "updating package-list..."
        updatePackageList
    fi
    if [ -n "$do_install" ]; then
        echo "checking if packages are missing... "
        installMissing
    fi
    echo "all done!"
}
commandLineInterface "$@"