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
PredUID=$8

RNA_SEQ_FILE=""$DATA_FOLDER"rna_seq.csv"
RNA_SEQ_PRE=""$DATA_FOLDER"RNAseq_pre.txt"
CTCF_FILE=""$DATA_FOLDER"ctcf.csv"
CTCF_CUT_FILE=""$DATA_FOLDER"ctcf_cut.csv"
CTCF_ORIENT_FILE=""$DATA_FOLDER"ctcf_orient.csv"
CTCF_ORIENT_PURE_FILE=""$DATA_FOLDER"ctcf_orient_bez_vsyakoy_srani_kotoruyu_pihaet_v_stdout_gimmemotifs.csv"
CTCF_WEIGHTS="./input/CTCF_from_Jaspar2016.pwm"

MODEL_PATH="./trained_models_for_web_3DPredictor/"$MODEL""

OUT_FILE=""$DATA_FOLDER"result_predicted.csv"
MAIL_TEXT=""$DATA_FOLDER"mail.html"

# pipeline

START_TIMESTAMP=$(date +%s)
START_TIME=$(date +'%Y-%m-%d %H:%M:%S' --date="@"$START_TIMESTAMP"")

LOG_FILE="./_logs/"$(date +'%Y%m%d_%H%M%S' --date="@"$START_TIMESTAMP"")"-"$PredUID"_log.txt"
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

echo "<h1>3DPredictor Report</h1><p><b>Genome assembly:</b> "$2"</p><p><b>Chrom:</b> "$3"</p><p><b>Interval Start:</b> "$4"</p><p><b>Interval End:</b> "$5"</p><p><b>Model:</b> "$6"</p><hr><p><b>Started:</b> "$(date +'%Y-%m-%d %H:%M:%S' --date="@"$START_TIMESTAMP"")" [NSK]</p>" > $MAIL_TEXT

echo "# ctcf orient" >> $LOG_FILE

source ./_pyenv/bin/activate gimme >> $LOG_FILE 2>> $LOG_FILE
cut -f 1-7 $CTCF_FILE > $CTCF_CUT_FILE 2>> $LOG_FILE
gimme scan $CTCF_CUT_FILE -g ./_pyenv/genomes/$GENOME/$GENOME.fa -p $CTCF_WEIGHTS -n 10 -b > $CTCF_ORIENT_FILE 2>> $LOG_FILE

if [[ ${PIPESTATUS[0]} -ne 0 ]];
then {
    echo "<p><p><b>Status:</b> Failed</p>" >> $MAIL_TEXT
    python3 email_sender.py ""$EMAIL"" ""$MAIL_TEXT"" ""$OUT_FILE"" >> $LOG_FILE 2>> $LOG_FILE
    trap 'echo "Error: gimme stopped with exit code 1" >> $LOG_FILE' EXIT
} fi

grep '^[^#].*$' $CTCF_ORIENT_FILE > $CTCF_ORIENT_PURE_FILE 2>> $LOG_FILE
conda activate base >> $LOG_FILE 2>> $LOG_FILE

echo "# rnaseq file preparation" >> $LOG_FILE
python3 get_appropriate_data_formats.py $RNA_SEQ_FILE $RNA_SEQ_PRE $GENOME >> $LOG_FILE 2>> $LOG_FILE

if [[ ${PIPESTATUS[0]} -ne 0 ]];
then {
echo "<p><p><b>Status:</b> Failed</p>" >> $MAIL_TEXT
python3 email_sender.py ""$EMAIL"" ""$MAIL_TEXT"" ""$OUT_FILE"" >> $LOG_FILE 2>> $LOG_FILE
trap 'echo "Error: get_appropriate_data_formats.py stopped with exit code 1" >> $LOG_FILE' EXIT
} fi

echo "# PREDICTION" >> $LOG_FILE
python3 web_3DPredictor.py Predictor -N $RNA_SEQ_PRE -C $CTCF_FILE -o $CTCF_ORIENT_PURE_FILE -g $GENOME -c $CHROM -s $INTERVAL_START -e $INTERVAL_END -O $OUT_FILE -m $MODEL_PATH >> $LOG_FILE 2>> $LOG_FILE

if [[ ${PIPESTATUS[0]} -ne 0 ]];
then {
echo "<p><p><b>Status:</b> Failed</p>" >> $MAIL_TEXT
python3 email_sender.py ""$EMAIL"" ""$MAIL_TEXT"" ""$OUT_FILE"" >> $LOG_FILE 2>> $LOG_FILE
trap 'echo "Error: web_3DPredictor.py stopped with exit code 1" >> $LOG_FILE' EXIT
} fi

END_TIMESTAMP=$(date +%s)
DURATION=$(($END_TIMESTAMP - $START_TIMESTAMP))
echo "<p><b>Duration:</b> "$(date -d@$DURATION -u '+%H h %M min %S sec')"</p><p><b>Status:</b> Success</p>" >> $MAIL_TEXT

echo "# email" >> $LOG_FILE
python3 email_sender.py ""$EMAIL"" ""$MAIL_TEXT"" ""$OUT_FILE"" >> $LOG_FILE 2>> $LOG_FILE
rm -rf $DATA_FOLDER
