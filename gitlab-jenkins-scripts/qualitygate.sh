#!/bin/bash

declare -r SONAR_TOKEN="8d66cd284884ec7103c17efb74865c87bc0f387b"

function readUrl() {
    curl -s -u "$SONAR_TOKEN": "$1"
}

function getJsonValue() {
    local json="$1"
    local key="$2"

    IFS=',' read -ra PARTS <<< "$json"
    for part in "${PARTS[@]}"; do
        if echo ${part} | grep "$key">/dev/null; then
            line="$part"
        fi
    done

    IFS=':' read -ra PARTS <<< "$line"
    echo ${PARTS[1]//\"/}
    printf ${PARTS[1]//\"/}
}

function readTaskId() {
    sonarResultFile="$1"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if echo "$line" | grep "ceTaskId">/dev/null; then
            IFS='=' read -ra PARTS <<< "$line"
            echo ${PARTS[1]}
            return 0
        fi
    done < "$sonarResultFile"
    exit 1
}

function checkStatus() {
    taskData=$(readUrl $1)
    taskStatus=$(getJsonValue "${taskData}" "status")
    if [[ "$taskStatus" == "PENDING"   ]] || [[ "$taskStatus" == "IN_PROGRESS" ]]; then
        sleep 10
        checkStatus $1
    fi
}

function main() {
    taskId=$(readTaskId "target/sonar/report-task.txt")
    taskUrl="http://192.168.0.45:9000/api/ce/task?id=${taskId}"
    checkStatus ${taskUrl}
    taskData=$(readUrl ${taskUrl})
    analysisId=$(getJsonValue "${taskData}" "analysisId")
    analysisUrl="http://192.168.0.45:9000/api/qualitygates/project_status?analysisId=${analysisId}"
    analysisData=$(readUrl ${analysisUrl})
    printf "%s\n" "${analysisData}"
    if echo ${analysisData} | grep "ERROR">/dev/null; then
        printf "%s\n" "Quality gate failed!\n"
        exit 1
    fi
    if echo ${analysisData} | grep "OK">/dev/null; then
        printf "%s\n" "Quality gate passed!"
        exit 0
    fi
    exit 1
}

main