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

function rollbackMerge(){
    git merge --abort
}

function showConflicts(){
    redMessage "============================"
    rollbackMerge
    git merge $MAIN_BRANCH | grep CONFLICTO > $CURRENT_PATH/merge-output
    cat $CURRENT_PATH/merge-output
    rm $CURRENT_PATH/merge-output
    redMessage "============================"
}

function update(){
    folder=$1
    project_name=$2

    blueTitleMessage "Update $project_name..."

    cd $folder
    git checkout $MAIN_BRANCH
    git pull
    git checkout $WORK_BRANCH
    greenTitleMessage "$project_name done!"
    
    echo ""
}

function merge(){
    folder=$1
    project_name=$2

    blueTitleMessage "[$project_name] Try to merge $MAIN_BRANCH into $WORK_BRANCH..."

    cd $folder
    git checkout $WORK_BRANCH
    output=$(git merge $MAIN_BRANCH)

    if [[ "$output" == *"falló"* ]]; then
        redTitleMessage "[$project_name] Merge fallido"
        showConflicts
        blueTitleMessage "[$project_name] Try to do a rollback (git merge --abort)..."
        rollbackMerge
        greenTitleMessage "[$project_name] Rollback done!"

        failedProjects+=($project_name)
    else
        okProjects+=($project_name)
    fi

    # ask
    greenTitleMessage "[$project_name] Merged!."
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