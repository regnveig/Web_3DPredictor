#!/bin/bash

function Killer() { lst=$(jobs -p); if [[ "$lst" = "" ]]; then :; else { kill -s KILL $lst; echo "Killed jobs: "$lst""; echo; } fi; }
function Logo() { echo "--- 3Dpredictor Pipeline Log ---"; echo; echo "Now: "$(date +'%Y-%m-%d %H:%M:%S')""; echo; Killer; }

START_TIME=$(date +'%Y-%m-%d %H:%M:%S')
START_TIMESTAMP=$(date +%s)

DATA_FOLDER=${BASH_ARGV[1]}
GENOME=${BASH_ARGV[2]}
CHROM=${BASH_ARGV[3]}
INTERVAL_START=${BASH_ARGV[4]}
INTERVAL_END=${BASH_ARGV[5]}
MODEL=${BASH_ARGV[6]}
EMAIL=${BASH_ARGV[7]}

RNA_SEQ_FILE=""$DATA_FOLDER"/rna_seq.csv"
RNA_SEQ_PRE=""$DATA_FOLDER"/RNAseq_pre.txt"
CTCF_FILE=""$DATA_FOLDER"/ctcf.csv"
CTCF_ORIENT_FILE=""$DATA_FOLDER"/ctcf_orient.csv"
CTCF_WEIGHTS="./CTCF_from_Jaspar2016.pwm"

MODEL_PATH="./trained_models_for_web_3DPredictor/"$MODEL""

LOG_FILE=""$DATA_FOLDER"/log.txt"

Logo > $LOG_FILE

conda activate gimme >> $LOG_FILE
gimme $CTCF_FILE -g $GENOME -p $CTCF_WEIGHTS  -n 10 -b > $CTCF_ORIENT_FILE 2>> $LOG_FILE

if [[ ${PIPESTATUS[0]} -ne 0 ]]; then {
       trap 'echo "Error: gimme stopped with exit code 1" >> $LOG_FILE' EXIT
} fi

conda deactivate >> $LOG_FILE

python3 get_appropriate_data_formats.py $RNA_SEQ_FILE $RNA_SEQ_PRE $GENOME >> $LOG_FILE

if [[ ${PIPESTATUS[0]} -ne 0 ]]; then {
	trap 'echo "Error: get_appropriate_data_formats.py stopped with exit code 1" >> $LOG_FILE' EXIT;
} fi

