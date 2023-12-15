#!/bin/bash

gh pr list -B Test -H Dev

echo "----------------------------------------------"

gh pr list -B Test -H Dev | grep 'no pull requests match your search'

echo "----------------------------------------------"

gh pr list -B Test -H Dev | awk '/no/ {print}'

echo "----------------------------------------------"

output=$(eval "gh pr list -B Test -H Dev") 
echo "This is my var: ${output}"

if [[ -z "${output}" ]]; then 
    echo "var is empty"
else
    echo "var is not empty"
fi

echo "----------------------------------------------"

aoutput=$(gh pr list --base main --head Test) 
echo "This is my var: ${aoutput}"

if [[ -z "${aoutput}" ]]; then 
    echo "var is empty"
else
    echo "var is not empty"
fi

echo "----------------------------------------------"

output=$(gh pr list) 
echo "This is my var: ${dumboutput}"

if [[ -z "${dumboutput}" ]]; then 
    echo "var is empty"
else
    echo "var is not empty"
fi

echo "----------------------------------------------"

output=$(echo "$(gh pr list --base main --head Test)") 
echo "This is my var: ${outputz}"

if [[ -z "${outputz}" ]]; then 
    echo "var is empty"
else
    echo "var is not empty"
fi

echo "----------------------------------------------"
echo "----------------TESTING 1---------------------"
echo "----------------------------------------------"
echo "----------------------------------------------"


aoutput=$(gh pr list --base main --head Test) 
echo "This is my var: ${aoutput}"

if [[ -z "${aoutput}" ]]; then 
    echo "var is empty"
else
    echo "var is not empty"
fi


echo "----------------------------------------------"
echo "----------------TESTING 2---------------------"
echo "----------------------------------------------"
echo "----------------------------------------------"


aboutput=$(gh pr list --base Test --head Dev) 
echo "This is my var: ${aboutput}"

if [[ -z "${aboutput}" ]]; then 
    echo "var is empty"
else
    echo "var is not empty"
fi
