#! /usr/bin/env bash

menu_options=(1 kc705 2 readout)
selected_number=$(dialog --keep-tite --menu "dRICH config menu" 12 50 5 "${menu_options[@]}" 2>&1 >/dev/tty)
[ $? -ne 0 ] && exit 0
selected_option="${menu_options[$((selected_number * 2 - 2)) + 1]}"
sudo emacs -nw /etc/drich/drich_$selected_option.conf

