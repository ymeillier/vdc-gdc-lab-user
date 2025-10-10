#!/bin/bash

red="\033[1;31m"
bold="\033[1m"
reset="\033[0m"  # Reset to default formatting

echo -e "${red}${bold}Enter the CRD auth command (https://remotedesktop.google.com/headless): ${reset}"
read crd_auth_command
echo "$crd_auth_command" > assets-jump-host/crd-auth-command.txt