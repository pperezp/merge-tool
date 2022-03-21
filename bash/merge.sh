#!/bin/bash

# Description: 
#   MAIN_BRANCH will pull and WORK_BRANCH will merge with MAIN_BRANCH
#   https://stackoverflow.com/questions/54087481/assigning-an-array-parsed-with-jq-to-bash-script-array
# 
# Example:
#   # execute
#   sh merge config.json

function validate_config_file() {
    if [ -z $1 ]; then 
        echo -e "\e[31m[ERROR]\e[0m You need to pass a config file in params"
        echo "Example: sh merge.sh config.json"
        exit
    fi
}

validate_config_file $1
CONFIG_FILE=$1
MAIN_BRANCH=$(cat $CONFIG_FILE | jq ."mainBranch" --raw-output)
WORK_BRANCH=$(cat $CONFIG_FILE | jq ."workBranch" --raw-output)
PROJECTS=$((<$CONFIG_FILE jq -r '.projects | @sh')| tr -d \') 

ok_projects=()
failed_projects=()
conflict_files_counts=()

function blue_message() {
    echo -e "\e[34m$1\e[0m"
}

function green_message() {
    echo -e "\e[32m$1\e[0m"
}

function red_message() {
    echo -e "\e[31m$1\e[0m"
}

function blue_title_message() {
    blue_message "[$1]"
}

function green_title_message() {
    green_message "[$1]"
}

function red_title_message() {
    red_message "[$1]"
}

function ask_to_continue() {
    while true; do
        read -p "Continue? [Y/n]: " answer
        case $answer in
            [Nn]* ) exit;;
            * ) break;;
        esac
    done
}

function abort_merge() {
    git merge --abort
}

function show_conflicts() {
    red_message "============================"
    abort_merge
    git merge $MAIN_BRANCH | grep CONFLICTO > $PWD/merge-output
    conflict_files_count=$(wc -l < $PWD/merge-output)
    conflict_files_counts+=($conflict_files_count)
    cat $PWD/merge-output
    rm $PWD/merge-output
    red_message "============================"
}

function pull() {
    folder=$1
    cd $folder
    project_name=${PWD##*/}

    blue_title_message "Pull $project_name..."

    git checkout $MAIN_BRANCH
    git pull
    git checkout $WORK_BRANCH
    green_title_message "$project_name has pulled!"
    
    echo ""
}

function merge() {
    folder=$1
    cd $folder
    project_name=${PWD##*/}

    blue_title_message "[$project_name] Try to merge $MAIN_BRANCH into $WORK_BRANCH..."

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

    echo ""
}

function pull_call() {
    for project in ${PROJECTS[@]}; do
        pull $project
    done
}

function merge_call() {
    for project in ${PROJECTS[@]}; do
        merge $project
    done
}

function show_results() {
    green_title_message "MERGED $MAIN_BRANCH into $WORK_BRANCH"
    ok_projects_count=${#ok_projects[@]}

    if [[ $ok_projects_count == 0 ]]; then
        echo "• No projects are merged"
    fi

    for project in ${ok_projects[@]}; do
        echo -e "\e[32m✔\e[0m $project"
    done

    echo ""

    red_title_message "FAILED (Merge was aborted)"

    failed_projects_count=${#failed_projects[@]}

    if [[ $failed_projects_count == 0 ]]; then
        echo "• No projects with merge errors"
    fi

    for i in "${!failed_projects[@]}"; do 
        echo -e "\e[31m✘\e[0m ${failed_projects[$i]} (${conflict_files_counts[$i]})"
    done
}

function print_projects() {
    for project in ${PROJECTS[@]}; do
        cd $project
        project_name=${PWD##*/}

        echo -e "\e[32m\e[1m    ➔\e[0m $project_name"
    done
}

function show_config_file_information() {
    # "$1"
    current_PATH=$PWD
    echo -e "• \e[1m\e[35m$CONFIG_FILE\e[0m"
    echo -e "• \e[32m$MAIN_BRANCH\e[0m ➔ \e[33m$WORK_BRANCH\e[0m"
    echo -e "• \e[1mProyects\e[0m"
    print_projects
    ask_to_continue
    cd $PWD
    echo ""
}

show_config_file_information
pull_call
merge_call
show_results