#!/bin/bash

# Description: 
#   MAIN_BRANCH will pull and WORK_BRANCH will merge with MAIN_BRANCH

MAIN_BRANCH=master
WORK_BRANCH=feature/GOW-2845
MICROSERVICES=/home/prez/awto/microservices
GOWGO_PATH=/home/prez/awto/awto-gowgo-migration-project

ok_projects=()
failed_projects=()
conflict_files_counts=()

function blue_message(){
    echo -e "\e[34m$1\e[0m"
}

function green_message() {
    echo -e "\e[32m$1\e[0m"
}

function red_message() {
    echo -e "\e[31m$1\e[0m"
}

function blue_title_message(){
    blue_message "[$1]"
}

function green_title_message(){
    green_message "[$1]"
}

function red_title_message(){
    red_message "[$1]"
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

function abort_merge(){
    git merge --abort
}

function show_conflicts(){
    red_message "============================"
    abort_merge
    git merge $MAIN_BRANCH | grep CONFLICTO > $PWD/merge-output
    conflict_files_count=$(wc -l < $PWD/merge-output)
    conflict_files_counts+=($conflict_files_count)
    cat $PWD/merge-output
    rm $PWD/merge-output
    red_message "============================"
}

function pull(){
    folder=$1
    project_name=$2

    blue_title_message "Pull $project_name..."

    cd $folder
    git checkout $MAIN_BRANCH
    git pull
    git checkout $WORK_BRANCH
    green_title_message "$project_name has pulled!"
    
    echo ""
}

function merge(){
    folder=$1
    project_name=$2

    blue_title_message "[$project_name] Try to merge $MAIN_BRANCH into $WORK_BRANCH..."

    cd $folder
    git checkout $WORK_BRANCH
    output=$(git merge $MAIN_BRANCH)

    if [[ "$output" == *"falló"* ]]; then
        red_title_message "[$project_name] Merge has failed"
        show_conflicts
        blue_title_message "[$project_name] Try to abort merge (git merge --abort)..."
        abort_merge
        green_title_message "[$project_name] Merge aborted!"

        failed_projects+=($project_name)
    else
        ok_projects+=($project_name)
        green_title_message "[$project_name] Merged!."
    fi

    # ask
    echo ""
}

function pull_call(){
    pull $GOWGO_PATH gowgo
    pull $MICROSERVICES/ms-model ms-model
    pull $MICROSERVICES/ms-membership ms-membership
    pull $MICROSERVICES/ms-datatables ms-datatables
    pull $MICROSERVICES/ms-invoicing ms-invoicing
    pull $MICROSERVICES/ms-marketplace ms-marketplace
    pull $MICROSERVICES/ms-payments ms-payments
    pull $MICROSERVICES/ms-trips ms-trips
    pull $MICROSERVICES/ms-users ms-users
}

function merge_call(){
    merge $GOWGO_PATH gowgo
    merge $MICROSERVICES/ms-model ms-model
    merge $MICROSERVICES/ms-membership ms-membership
    merge $MICROSERVICES/ms-datatables ms-datatables
    merge $MICROSERVICES/ms-invoicing ms-invoicing
    merge $MICROSERVICES/ms-marketplace ms-marketplace
    merge $MICROSERVICES/ms-payments ms-payments
    merge $MICROSERVICES/ms-trips ms-trips
    merge $MICROSERVICES/ms-users ms-users
}

function show_results(){
    green_title_message "MERGED $MAIN_BRANCH into $WORK_BRANCH"
    for project in ${ok_projects[@]}; do
        echo -e "\e[32m✔\e[0m $project"
    done

    echo ""

    red_title_message "FAILED (Merge was aborted)"

    for i in "${!failed_projects[@]}"; do 
        echo -e "\e[31m✘\e[0m ${failed_projects[$i]} (${conflict_files_counts[$i]})"
    done
}

pull_call
merge_call
show_results