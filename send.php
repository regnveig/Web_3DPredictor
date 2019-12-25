<?php

$C_MIN_INTERVAL=20000;

echo print_r($_POST);
$coord=$_POST["coordinates"];
$chr=explode(':', $coord)[0];
$be=explode(':', $coord)[1];
$interval_start=intval(preg_replace("/[,]/", "", explode('-', $be)[0]));
$interval_end=intval(preg_replace("/[,]/", "", explode('-', $be)[1]));
if(($interval_end-$interval_start)<$C_MIN_INTERVAL) {
	echo "<div style=\"color: red;\">Bad chromosome interval (must be more than ".strval($C_MIN_INTERVAL)." bp)</div>";
	exit();
}
$model_path="/sf/storage/Web_3DPredictor/trained_models_for_web_3DPredictor/".$_POST["model"];

$f_pointer=fopen("./models_description.txt","r");
$cap=fgetcsv($f_pointer,0,"\t");
while(!feof($f_pointer)){
        $ar=fgetcsv($f_pointer,0,"\t");
	if($ar[1]==$_POST["model"]) { 
		$forbidden=explode(",", $ar[4]);
		$chr_number=substr($chr, 3);
		if(in_array($chr_number, $forbidden)) {
			echo "<div style=\"color: red;\">Bad chromosome (used in training), please choose another model</div>";
			exit();
		}
	}
}

$email=$_POST["email"];

echo "<b>Chrom:</b> ".$chr."<br>";
echo "<b>Interval Start:</b> ".$interval_start."<br>";
echo "<b>Interval End:</b> ".$interval_end."<br>";
echo "<b>Model path:</b> ".$model_path."<br>";
echo "<b>Email:</b> ".$email."<br>";
?>
