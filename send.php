<?php

function rmdir_recursive($dir) {
	foreach(scandir($dir) as $file) {
		if ('.' === $file || '..' === $file) continue;
		if (is_dir("$dir/$file")) rmdir_recursive("$dir/$file");
		else unlink("$dir/$file");
	}
	rmdir($dir);
}

function generateRandomString($length = 10) {
	$characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
	$charactersLength = strlen($characters);
	$randomString = '';
	for ($i = 0; $i < $length; $i++) {
		$randomString .= $characters[rand(0, $charactersLength - 1)];
	}
	return $randomString;
}

$C_MIN_INTERVAL=20000;

// VARIABLES CHECK

$coord=$_POST["coordinates"];
$chr=explode(':', $coord)[0];
$be=explode(':', $coord)[1];
$interval_start=intval(preg_replace("/[,]/", "", explode('-', $be)[0]));
$interval_end=intval(preg_replace("/[,]/", "", explode('-', $be)[1]));
if(($interval_end-$interval_start)<$C_MIN_INTERVAL) {
	echo "<div style=\"color: red; text-align: center;\">Bad chromosome interval (must be longer than ".strval($C_MIN_INTERVAL)." bp)</div>";
	exit();
}
$model_path=$_POST["model"];

$f_pointer=fopen("trained_models_for_web_3DPredictor/models_description.txt","r");
$cap=fgetcsv($f_pointer,0,"\t");
while(!feof($f_pointer)){
	$ar=fgetcsv($f_pointer,0,"\t");
	if($ar[1]==$_POST["model"]) { 
		$forbidden=explode(",", $ar[4]);
		$chr_number=substr($chr, 3);
		if(in_array($chr_number, $forbidden)) {
			echo "<div style=\"color: red; text-align: center;\">Bad chromosome number (used in training), please choose another model</div>";
			exit();
		}
	}
}

$email=$_POST["email"];
$genome_assembly=$_POST["genome_version"];

// FILES UPLOAD

$UID=generateRandomString(16);
$uploaddir = "./_temp/".$UID."/";
mkdir($uploaddir, 0777);

if ($_POST["rna_upload_type"]=="local") {
	if (!move_uploaded_file($_FILES['rna_local']['tmp_name'], $uploaddir."rna_seq.csv")) {
		echo "<div style=\"color: red; text-align: center;\">Upload local RNA-Seq file is failed</div>";
		rmdir_recursive($uploaddir);
		exit();
	}
}

if ($_POST["ctcf_upload_type"]=="local") {
	if (!move_uploaded_file($_FILES['ctcf_local']['tmp_name'], $uploaddir."ctcf.csv")) {
		echo "<div style=\"color: red; text-align: center;\">Upload local CTCF file is failed</div>";
		rmdir_recursive($uploaddir);
		exit();
	}
}

// FILES CHECK

$command = './_pyenv/bin/activate; ./_pyenv/bin/python3 check_file_formats.py "'.$uploaddir.'rna_seq.csv" "'.$uploaddir.'ctcf.csv" 2>&1';
$output = exec($command, $output, $exit_code);
if ($exit_code!=0) {
	echo "<div style=\"color: red; text-align: center;\">".$output."</div>";
	rmdir_recursive($uploaddir);
	exit();
}

// EXEC PIPELINE

$cmd = 'screen -dm ./pipeline.sh '.$uploaddir.' '.$genome_assembly.' '.$chr.' '.$interval_start.' '.$interval_end.' '.$model_path.' '.$email.' '.$UID;
shell_exec($cmd);

echo "<div style=\"color: green; text-align: center;\">Looks like most things are correct, wait for email :)</div>";
?>
