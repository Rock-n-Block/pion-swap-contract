#!/bin/bash

if [[ -f "./migrations/2_deploy_contracts.js" ]]
then
    rm ./migrations/2_deploy_contracts.js &
fi
truffle test