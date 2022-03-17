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
    blueMessage "Update $2..."
    cd $1
    git checkout $MAIN_BRANCH
    git pull
    git checkout $WORK_BRANCH
    echo -e "\e[32m$2 Done!.\e[0m"
}

function merge(){
    echo -e "\e[34mMerge $2...\e[0m"
    cd $1
    git checkout $WORK_BRANCH
    output=$(git merge $MAIN_BRANCH)

    if [[ "$output" == *"falló"* ]]; then
        echo -e "\e[31m$2 merge falló\e[0m"
        echo -e "\e[31m============================\e[0m"
        git merge --abort
        git merge $MAIN_BRANCH | grep CONFLICTO > $CURRENT_PATH/merge-output
        cat $CURRENT_PATH/merge-output
        rm $CURRENT_PATH/merge-output
        echo -e "\e[31m============================\e[0m"
        
        echo -e "\e[34mRollback (git merge --abort)...\e[0m"
        git merge --abort
        echo -e "\e[32m$2 Done!.\e[0m"
        failedProjects+=($2)
        echo "add $2 to fail"
        #exit
    else
        okProjects+=($2)
        echo "add $2 to ok"
    fi
    # ask
    echo -e "\e[32m$2 Done!.\e[0m"
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
    greenMessage "[MERGED]"
    for project in ${okProjects[@]}; do
        echo $project
    done

    redMessage "[FAILED]"
    for project in ${failedProjects[@]}; do
        echo $project
    done
}

updateCall
mergeCall
showResults