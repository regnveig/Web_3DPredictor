#!/bin/bash

# func
function Killer() { lst=$(jobs -p); if [[ "$lst" = "" ]]; then :; else { kill -s KILL $lst; echo "Killed jobs: "$lst""; echo; } fi; }
function Logo() { echo "--- 3Dpredictor Pipeline Log ---"; echo; echo "Now: "$(date +'%Y-%m-%d %H:%M:%S')""; echo; Killer; }
function FailHandler() {
	local l_MODULE_NAME=$1
	local l_EMAIL=$2
	local l_MAIL_TEXT=$3
	local l_LOG_FILE=$4
	echo "Error: "$l_MODULE_NAME" stopped with exit code 1" >> $l_LOG_FILE
	echo "# Email ..." >> $l_LOG_FILE
	echo "<p><p><b>Status:</b> Failed</p><hr><p>We are aware of your problem, and we will fix it as soon as possible.</p>" >> $l_MAIL_TEXT
	echo ""$(TS)" python3 email_sender.py "$l_EMAIL" "$l_MAIL_TEXT" no" >> $l_LOG_FILE
	python3 email_sender.py ""$l_EMAIL"" ""$l_MAIL_TEXT"" no >> $l_LOG_FILE 2>> $l_LOG_FILE
	echo "Done." >> $l_LOG_FILE
}
function TS() { date +'[%H:%M:%S]' >&1; }
function ReadAnyway() { ( zcat $1 || bzcat $1 || cat $1 ) >&1 2> /dev/null; }
function PureMD5() { local md5=( $(md5sum $1) ); echo ${md5[0]} >&1; }
function PureBytes() { local bytes=( $(du $1) ); echo ${bytes[0]} >&1; }

# vars
DATA_FOLDER=$1
GENOME=$2
CHROM=$3
INTERVAL_START=$4
INTERVAL_END=$5
MODEL=$6
EMAIL=$7
PredUID=$8
RESOLUTION=$9
RNASEQ_MODEL_PRE=${10}

RNA_SEQ_FILE=""$DATA_FOLDER"rna_seq.csv"
RNA_SEQ_FILE_READABLE=""$DATA_FOLDER"rna_seq_readable.csv"
RNA_SEQ_PRE=""$DATA_FOLDER"RNAseq_pre.txt"
CTCF_FILE=""$DATA_FOLDER"ctcf.csv"
CTCF_FILE_READABLE=""$DATA_FOLDER"ctcf_readable.csv"
CTCF_CUT_FILE=""$DATA_FOLDER"ctcf_cut.csv"
CTCF_ORIENT_FILE=""$DATA_FOLDER"ctcf_orient.csv"
CTCF_ORIENT_PURE_FILE=""$DATA_FOLDER"ctcf_orient_pure.csv"
CTCF_WEIGHTS="./input/CTCF_from_Jaspar2016.pwm"

MODEL_PATH="./trained_models_for_web_3DPredictor/"$MODEL""

OUT_FILE=""$DATA_FOLDER"result_predicted.csv"
HIC_CHROMSIZES=""$DATA_FOLDER"hic_chromsizes.txt"
HIC_PRE=""$DATA_FOLDER"hic_pre.txt"
MAIL_TEXT=""$DATA_FOLDER"mail.html"

# pipeline

START_TIMESTAMP=$(date +%s)
START_TIME=$(date +'%Y-%m-%d %H:%M:%S' --date="@"$START_TIMESTAMP"")

LOG_FILE="./_logs/"$(date +'%Y%m%d_%H%M%S' --date="@"$START_TIMESTAMP"")"-"$PredUID"_log.txt"
HIC_FILE=""$DATA_FOLDER"3DPredictor_result_"$(date +'%Y%m%d_%H%M%S' --date="@"$START_TIMESTAMP"")".hic"
Logo > $LOG_FILE
echo "COMMAND LINE DATA" >> $LOG_FILE
echo >> $LOG_FILE
echo "Data folder: "$DATA_FOLDER"" >> $LOG_FILE
echo "Genome assembly: "$GENOME"" >> $LOG_FILE
echo "Chrom: "$CHROM"" >> $LOG_FILE
echo "Interval Start: "$INTERVAL_START"" >> $LOG_FILE
echo "Interval End: "$INTERVAL_END"" >> $LOG_FILE
echo "Model: "$MODEL"" >> $LOG_FILE
echo "Resolution: "$RESOLUTION"" >> $LOG_FILE
echo "RNA-Seq Model File: "$RNASEQ_MODEL_PRE"" >> $LOG_FILE
echo "Email: "$EMAIL"" >> $LOG_FILE
echo >> $LOG_FILE
echo "<h1>3DPredictor Report</h1><p><b>Genome assembly:</b> "$GENOME"</p><p><b>Chrom:</b> "$CHROM"</p><p><b>Interval Start:</b> "$INTERVAL_START"</p><p><b>Interval End:</b> "$INTERVAL_END"</p><p><b>Model:</b> "$MODEL"</p><p><b>Resolution:</b> "$RESOLUTION"</p><p><b>Started:</b> "$(date +'%Y-%m-%d %H:%M:%S' --date="@"$START_TIMESTAMP"")" [NSK]</p>" > $MAIL_TEXT

# Uploads

echo "# Uploads Check ..." >> $LOG_FILE
echo "CTCF Size: "$(PureBytes $CTCF_FILE)"K, MD5: "$(PureMD5 $CTCF_FILE)"" >> $LOG_FILE
echo "RNA-Seq Size: "$(PureBytes $RNA_SEQ_FILE)"K, MD5: "$(PureMD5 $RNA_SEQ_FILE)"" >> $LOG_FILE
echo >> $LOG_FILE
echo "<p><b>CTCF Size:</b> "$(PureBytes $CTCF_FILE)"K, <b>MD5:</b> "$(PureMD5 $CTCF_FILE)"</p><p><b>RNA-Seq Size:</b> "$(PureBytes $RNA_SEQ_FILE)"K, <b>MD5:</b> "$(PureMD5 $RNA_SEQ_FILE)"</p>" >> $MAIL_TEXT

# CTCF Orient

echo "# CTCF Orient ..." >> $LOG_FILE
echo ""$(TS)" source ./_pyenv/bin/activate gimme" >> $LOG_FILE
source ./_pyenv/bin/activate gimme >> $LOG_FILE 2>> $LOG_FILE
echo ""$(TS)" ReadAnyway "$CTCF_FILE" > "$CTCF_FILE_READABLE"" >> $LOG_FILE
ReadAnyway $CTCF_FILE > $CTCF_FILE_READABLE 2>> $LOG_FILE
echo ""$(TS)" cut -f 1-7 "$CTCF_FILE_READABLE" > "$CTCF_CUT_FILE"" >> $LOG_FILE
cut -f 1-7 $CTCF_FILE_READABLE > $CTCF_CUT_FILE 2>> $LOG_FILE
echo ""$(TS)" gimme scan "$CTCF_CUT_FILE" -g ./_pyenv/genomes/"$GENOME"/"$GENOME".fa -p "$CTCF_WEIGHTS" -n 10 -b > "$CTCF_ORIENT_FILE"" >> $LOG_FILE
gimme scan $CTCF_CUT_FILE -g ./_pyenv/genomes/$GENOME/$GENOME.fa -p $CTCF_WEIGHTS -n 10 -b > $CTCF_ORIENT_FILE 2>> $LOG_FILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then { FailHandler gimme $EMAIL $MAIL_TEXT $LOG_FILE; exit 1; } fi
echo ""$(TS)" grep '^[^#].*$' "$CTCF_ORIENT_FILE" > "$CTCF_ORIENT_PURE_FILE"" >> $LOG_FILE
grep '^[^#].*$' $CTCF_ORIENT_FILE > $CTCF_ORIENT_PURE_FILE 2>> $LOG_FILE
echo "Done." >> $LOG_FILE
echo >> $LOG_FILE

# RNA-Seq File Preparation

echo "# RNA-Seq File Preparation ..." >> $LOG_FILE
echo ""$(TS)" conda activate base" >> $LOG_FILE
conda activate base >> $LOG_FILE 2>> $LOG_FILE
echo ""$(TS)" ReadAnyway "$RNA_SEQ_FILE" > "$RNA_SEQ_FILE_READABLE"" >> $LOG_FILE
ReadAnyway $RNA_SEQ_FILE > $RNA_SEQ_FILE_READABLE 2>> $LOG_FILE
echo ""$(TS)" python3 get_appropriate_data_formats.py "$RNA_SEQ_FILE_READABLE" "$RNA_SEQ_PRE" "$GENOME" ./input/model_predictors/"$RNASEQ_MODEL_PRE"" >> $LOG_FILE
python3 get_appropriate_data_formats.py $RNA_SEQ_FILE_READABLE $RNA_SEQ_PRE $GENOME ./input/model_predictors/$RNASEQ_MODEL_PRE >> $LOG_FILE 2>> $LOG_FILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then { FailHandler get_appropriate_data_formats.py $EMAIL $MAIL_TEXT $LOG_FILE; exit 1; } fi
echo "Done." >> $LOG_FILE
echo >> $LOG_FILE

# Prediction

echo "# Prediction ..." >> $LOG_FILE
echo ""$(TS)" python3 web_3DPredictor.py Predictor -N "$RNA_SEQ_PRE" -C "$CTCF_FILE_READABLE" -o "$CTCF_ORIENT_PURE_FILE" -g "$GENOME" -c "$CHROM" -s "$INTERVAL_START" -e "$INTERVAL_END" -O "$OUT_FILE" -m "$MODEL_PATH" -r "$RESOLUTION"" >> $LOG_FILE
python3 web_3DPredictor.py Predictor -N $RNA_SEQ_PRE -C $CTCF_FILE_READABLE -o $CTCF_ORIENT_PURE_FILE -g $GENOME -c $CHROM -s $INTERVAL_START -e $INTERVAL_END -O $OUT_FILE -m $MODEL_PATH -r $RESOLUTION >> $LOG_FILE 2>> $LOG_FILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then { FailHandler web_3DPredictor.py $EMAIL $MAIL_TEXT $LOG_FILE; exit 1; } fi
echo "Done." >> $LOG_FILE
echo >> $LOG_FILE

# Pre-HiC

echo "# Pre-HiC ..." >> $LOG_FILE
echo ""$(TS)" python3 GetPreForHic.py "$OUT_FILE" "$HIC_CHROMSIZES" "$HIC_PRE"" >> $LOG_FILE
python3 GetPreForHic.py $OUT_FILE $HIC_CHROMSIZES $HIC_PRE >> $LOG_FILE 2>> $LOG_FILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then { FailHandler GetPreForHic.py $EMAIL $MAIL_TEXT $LOG_FILE; exit 1; } fi
echo "Done." >> $LOG_FILE
echo >> $LOG_FILE

# HiC Map

echo "# HiC Map ..." >> $LOG_FILE
echo ""$(TS)" java -jar ./3Dpredictor/source/juicer_tools.jar pre "$HIC_PRE" "$HIC_FILE" "$HIC_CHROMSIZES" -n -r "$RESOLUTION"" >> $LOG_FILE
java -jar ./3Dpredictor/source/juicer_tools.jar pre $HIC_PRE $HIC_FILE $HIC_CHROMSIZES -n -r $RESOLUTION >> $LOG_FILE 2>> $LOG_FILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then { FailHandler juicer_tools.jar $EMAIL $MAIL_TEXT $LOG_FILE; exit 1; } fi
echo "Done." >> $LOG_FILE
echo >> $LOG_FILE

# Success Email

echo "# Email ..." >> $LOG_FILE
END_TIMESTAMP=$(date +%s)
DURATION=$(($END_TIMESTAMP - $START_TIMESTAMP))
echo "<p><b>Duration:</b> "$(date -d@$DURATION -u '+%H h %M min %S sec')"</p><p><b>Status:</b> Success</p><hr><p>Attachment is a HiC map with predicted contacts.</p>" >> $MAIL_TEXT
echo ""$(TS)" python3 email_sender.py "$EMAIL" "$MAIL_TEXT" "$HIC_FILE"" >> $LOG_FILE
python3 email_sender.py ""$EMAIL"" ""$MAIL_TEXT"" ""$HIC_FILE"" >> $LOG_FILE 2>> $LOG_FILE
echo "Done." >> $LOG_FILE
echo >> $LOG_FILE

# Folder Delete

echo "# Delete Temp Files ..." >> $LOG_FILE
echo ""$(TS)" rm -rf "$DATA_FOLDER"" >> $LOG_FILE
rm -rf $DATA_FOLDER >> $LOG_FILE 2>> $LOG_FILE
