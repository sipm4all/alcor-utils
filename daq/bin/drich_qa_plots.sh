#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo " usage: $0 [run-name] "
    exit 1
fi
runname=$1

/home/eic/bin/telegram_message.sh "QA plots requested for run ${runname}, hold on "
#ssh eic@eicdesk04.cern.ch "cd $HOME/QA; ./drich_online_qa.sh ${runname}" &> /tmp/drich_qa_plots.$runname.log

### this is new stuff for cosmic-ray tests

/home/eic/bin/telegram_message.sh "running analysis: ${runname}" && root -b -q -l "/home/eic/alcor/alcor-utils/pdu/measure/sipm4eic-testbeam2023-analysis/macros/lightwriter.C(\"/home/eic/DATA/2023-testbeam/actual/physics/${runname}/\", \"/home/eic/DATA/2023-testbeam/actual/physics/${runname}/lightdata.root\", \"/home/eic/DATA/2023-testbeam/actual/physics/${runname}/finedata.root\")" &> /home/eic/DATA/2023-testbeam/actual/physics/${runname}/lightwriter.log  && rm -rf /home/eic/DATA/2023-testbeam/actual/physics/${runname}/kc705-* && /home/eic/bin/telegram_message.sh "analysis completed: ${runname}"

