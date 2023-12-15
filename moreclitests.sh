#!/bin/bash

output=$(gh pr list --base main --head Test) 

if [[ -z "${output}" ]]; then 
    echo "var is empty"
else
    echo "var is not empty"
    echo $output
fi

