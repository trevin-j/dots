#!/bin/sh

printf 'New session name: '
IFS= read -r new_name || exit 0

[ -n "$new_name" ] || exit 0

zellij action rename-session "$new_name"
