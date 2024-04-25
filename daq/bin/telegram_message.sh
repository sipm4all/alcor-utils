#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo " usage: $0 [message] "
    exit 1
fi
message="$(hostname) -- $1"

chatid=-1001866731573 ### group 
chatid=625973013 ### roberto
chatid=-1001983362927 ### 2023 channel
chatid=-1002098739640 ### 2024 channel

timeout 10 curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=$chatid -F text="$message" "https://api.telegram.org/bot6485476926:AAEqeA-ynsn4fzHFzWQdPQs2LgnwgwXOSpk/sendMessage" &> /dev/null

