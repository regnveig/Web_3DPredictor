#!/bin/bash

function Killer() { lst=$(jobs -p); if [[ "$lst" = "" ]]; then :; else { kill -s KILL $lst; echo "Killed jobs: "$lst""; echo; } fi; }
function Logo() { echo "--- 3Dpredictor Pipeline Log ---"; echo; echo "Now: "$(date +'%Y-%m-%d %H:%M:%S')""; echo; Killer; }

DATA_FOLDER=${BASH_ARGV[1]}
GENOME=${BASH_ARGV[2]}
LOG_FILE=""$DATA_FOLDER"/log.txt"

Logo > $LOG_FILE

conda activate gimme >> $LOG_FILE
gimme ""$DATA_FOLDER"/ctcf.csv" -g $GENOME -p ./CTCF_from_Jaspar2016.pwm  -n 10 -b > ""$DATA_FOLDER"/ctcf_orient.csv" 2>> $LOG_FILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then { trap 'echo "Error: gimme stopped with exit code 1" >> $LOG_FILE' EXIT; }; fi
conda deactivate >> $LOG_FILE

python3 get_appropriate_data_formats.py ""$DATA_FOLDER"/rna_seq.csv" ""$DATA_FOLDER"/RNAseq_pre.txt" $GENOME >> $LOG_FILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then { trap 'echo "Error: get_appropriate_data_formats.py stopped with exit code 1" >> $LOG_FILE' EXIT; }; fi

