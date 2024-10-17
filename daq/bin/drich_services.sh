#! /usr/bin/env bash

menu_options=(1 data_http 2 kc705_monitor)
selected_number=$(dialog --keep-tite --menu "dRICH services menu" 16 50 5 "${menu_options[@]}" 2>&1 >/dev/tty)
[ $? -ne 0 ] && exit 0
selected_service="${menu_options[$((selected_number * 2 - 2)) + 1]}"

menu_options=(1 status 2 restart 3 start 4 stop 5 disable 6 enable)
selected_number=$(dialog --keep-tite --menu "dRICH ${selected_service} action" 14 50 5 "${menu_options[@]}" 2>&1 >/dev/tty)
[ $? -ne 0 ] && exit 0
selected_action="${menu_options[$((selected_number * 2 - 2)) + 1]}"

systemctl --user $selected_action $selected_service

