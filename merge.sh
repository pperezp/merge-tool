#!/bin/bash

WORK_BRANCH=feature/GOW-2845
MAIN_BRANCH=master
MICROSERVICES=/home/prez/awto/microservices
CURRENT_PATH=$PWD

okProjects=()
failedProjects=()

echo $CURRENT_PATH

function blueMessage(){
    echo -e "\e[34m$1\e[0m"
}

function greenMessage() {
    echo -e "\e[32m$1\e[0m"
}

function redMessage() {
    echo -e "\e[31m$1\e[0m"
}

function blueTitleMessage(){
    blueMessage "[$1]"
}

function greenTitleMessage(){
    greenMessage "[$1]"
}

function redTitleMessage(){
    redMessage "[$1]"
}

function ask(){
    while true; do
        read -p "Continue? [Y/n]: " yn
        case $yn in
            [Nn]* ) exit;;
            * ) break;;
        esac
    done
}

function update(){
    blueTitleMessage "Update $2..."
    cd $1
    git checkout $MAIN_BRANCH
    git pull
    git checkout $WORK_BRANCH
    greenTitleMessage "$2 Done!."
    echo ""
}

function merge(){
    blueTitleMessage "[$2] Try to merge $MAIN_BRANCH into $WORK_BRANCH..."
    cd $1
    git checkout $WORK_BRANCH
    output=$(git merge $MAIN_BRANCH)

    if [[ "$output" == *"falló"* ]]; then
        redTitleMessage "[$2] Merge fallido"
        redMessage "============================"
        git merge --abort
        git merge $MAIN_BRANCH | grep CONFLICTO > $CURRENT_PATH/merge-output
        cat $CURRENT_PATH/merge-output
        rm $CURRENT_PATH/merge-output
        redMessage "============================"
        
        blueTitleMessage "[$2] Try to do a rollback (git merge --abort)..."
        git merge --abort
        greenTitleMessage "[$2] Rollback done!."

        failedProjects+=($2)
    else
        okProjects+=($2)
    fi

    # ask
    greenTitleMessage "[$2] Merged!."
    echo ""
}

function updateCall(){
    update /home/prez/awto/awto-gowgo-migration-project gowgo
    update $MICROSERVICES/ms-model ms-model
    update $MICROSERVICES/ms-membership ms-membership
    update $MICROSERVICES/ms-datatables ms-datatables
    update $MICROSERVICES/ms-invoicing ms-invoicing
    update $MICROSERVICES/ms-marketplace ms-marketplace
    update $MICROSERVICES/ms-payments ms-payments
    update $MICROSERVICES/ms-trips ms-trips
    update $MICROSERVICES/ms-users ms-users
}

function mergeCall(){
    merge /home/prez/awto/awto-gowgo-migration-project gowgo
    merge $MICROSERVICES/ms-model ms-model
    merge $MICROSERVICES/ms-membership ms-membership
    merge $MICROSERVICES/ms-datatables ms-datatables
    merge $MICROSERVICES/ms-invoicing ms-invoicing
    merge $MICROSERVICES/ms-marketplace ms-marketplace
    merge $MICROSERVICES/ms-payments ms-payments
    merge $MICROSERVICES/ms-trips ms-trips
    merge $MICROSERVICES/ms-users ms-users
}

function showResults(){
    greenTitleMessage "MERGED $MAIN_BRANCH into $WORK_BRANCH"
    for project in ${okProjects[@]}; do
        echo -e "\e[32m✔\e[0m $project"
    done

    echo ""

    redTitleMessage "FAILED (Merge was aborted)"
    for project in ${failedProjects[@]}; do
        echo -e "\e[31m✘\e[0m $project"
    done
}

updateCall
mergeCall
showResults