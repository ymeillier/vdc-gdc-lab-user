#!/bin/bash
# script_dir=$(dirname "$0")  # Get the directory of the wrapper script
# exec "${script_dir}/get_crd_auth.sh" < /dev/tty > /dev/tty 2>&1

exec "assets-jump-host/scripts/get_crd_auth.sh" < /dev/tty > /dev/tty 2>&1