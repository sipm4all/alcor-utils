#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo " usage: $0 [picture] [caption] "
    exit 1
fi
picture=$1
caption="$(hostname) -- $2"

chatid=-1001866731573 ### group 
chatid=625973013 ### roberto
chatid=-1001983362927 ### 2023 channel
chatid=-1002098739640 ### 2024 channel

timeout 10 curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=$chatid -F photo=@$picture -F caption="$caption" "https://api.telegram.org/bot6485476926:AAEqeA-ynsn4fzHFzWQdPQs2LgnwgwXOSpk/sendPhoto" &> /dev/null
