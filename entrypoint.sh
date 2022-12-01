#!/bin/bash

if [ ! -z "$GATEWAY_ADDRESS" ]; then
    ip r d default 
    ip r a default via $GATEWAY_ADDRESS
fi

mkdir -p /tmp/.ICAClient
touch /tmp/.ICAClient/.eula_accepted

firefox
