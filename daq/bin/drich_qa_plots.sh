#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo " usage: $0 [run-name] "
    exit 1
fi
runname=$1

/home/eic/bin/telegram_message.sh "QA plots requested for run ${runname}, hold on "
ssh eic@eicdesk04.cern.ch "cd $HOME/QA; ./drich_online_qa.sh ${runname}" &> /tmp/drich_qa_plots.$runname.log
