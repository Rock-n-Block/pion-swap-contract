#!/bin/bash

if [[ ! -f "./migrations/2_deploy_contracts.js" ]]
then
    cp ./scripts/2_deploy_contracts.js ./migrations/
fi