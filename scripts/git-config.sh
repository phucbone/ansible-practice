#!/bin/bash

CONFIG_LIST=("user.name 'phucbone'" "user.email 'phuc.bone@gmail.com'" "color.ui 'auto'" "credential.helper 'store'")

for config in ${CONFIG_LIST[@]}; do
    sudo git config --global $config
done

sudo git config -l