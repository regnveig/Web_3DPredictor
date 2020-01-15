#!/bin/bash

# func
function Killer() { lst=$(jobs -p); if [[ "$lst" = "" ]]; then :; else { kill -s KILL $lst; echo "Killed jobs: "$lst""; echo; } fi; }
function Logo() { echo "--- 3Dpredictor Pipeline Log ---"; echo; echo "Now: "$(date +'%Y-%m-%d %H:%M:%S')""; echo; Killer; }

# vars
DATA_FOLDER=$1
GENOME=$2
CHROM=$3
INTERVAL_START=$4
INTERVAL_END=$5
MODEL=$6
EMAIL=$7

RNA_SEQ_FILE=""$DATA_FOLDER"/rna_seq.csv"
RNA_SEQ_PRE=""$DATA_FOLDER"/RNAseq_pre.txt"
CTCF_FILE=""$DATA_FOLDER"/ctcf.csv"
CTCF_ORIENT_FILE=""$DATA_FOLDER"/ctcf_orient.csv"
CTCF_WEIGHTS="./CTCF_from_Jaspar2016.pwm"

MODEL_PATH="./trained_models_for_web_3DPredictor/"$MODEL""

OUT_FILE=""$DATA_FOLDER"/result_predicted.csv"
LOG_FILE=""$DATA_FOLDER"/log.txt"

# pipeline

START_TIME=$(date +'%Y-%m-%d %H:%M:%S')
START_TIMESTAMP=$(date +%s)
Logo > $LOG_FILE

echo "COMMAND LINE DATA" >> $LOG_FILE
echo >> $LOG_FILE
echo "Data folder: "$1"" >> $LOG_FILE
echo "Genome assembly: "$2"" >> $LOG_FILE
echo "Chrom: "$3"" >> $LOG_FILE
echo "Interval Start: "$4"" >> $LOG_FILE
echo "Interval End: "$5"" >> $LOG_FILE
echo "Model path: "$6"" >> $LOG_FILE
echo "Email: "$7"" >> $LOG_FILE
echo >> $LOG_FILE

# ctcf orient
source ./_pyenv/bin/activate gimme >> $LOG_FILE
gimme scan $CTCF_FILE -g $GENOME -p $CTCF_WEIGHTS  -n 10 -b > $CTCF_ORIENT_FILE 2>> $LOG_FILE

if [[ ${PIPESTATUS[0]} -ne 0 ]];
then { trap 'echo "Error: gimme stopped with exit code 1" >> $LOG_FILE' EXIT; } fi

conda activate base >> $LOG_FILE

# rnaseq file preparation
python3 get_appropriate_data_formats.py $RNA_SEQ_FILE $RNA_SEQ_PRE $GENOME >> $LOG_FILE

if [[ ${PIPESTATUS[0]} -ne 0 ]];
then { trap 'echo "Error: get_appropriate_data_formats.py stopped with exit code 1" >> $LOG_FILE' EXIT; } fi

# PREDICTION
# python3 web_3DPredictor Predictor -N $RNA_SEQ_PRE -C $CTCF_FILE -o $CTCF_ORIENT_FILE -g $GENOME -c $CHROM -s $INTERVAL_START -e $INTERVAL_END -O $OUT_FILE -m $MODEL_PATH >> $LOG_FILE 2>> $LOG_FILE

# if [[ ${PIPESTATUS[0]} -ne 0 ]];
# then { trap 'echo "Error: web_3DPredictor.py stopped with exit code 1" >> $LOG_FILE' EXIT; } fi

# echo "Prediction successfully finished" >> $LOG_FILE
