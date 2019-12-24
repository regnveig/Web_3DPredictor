<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['recaptcha_response'])) {

    $recaptcha_url = 'https://www.google.com/recaptcha/api/siteverify';
    $recaptcha_secret = '6Le-ZMYUAAAAAHQ3i1FrRRiYuWE9SSX52V5UFnBb';
    $recaptcha_response = $_POST['recaptcha_response'];

    $recaptcha = file_get_contents($recaptcha_url . '?secret=' . $recaptcha_secret . '&response=' . $recaptcha_response);
    $recaptcha = json_decode($recaptcha);

    if ($recaptcha->score >= 0.5) {
	echo "<p align=\"center\" style=\"color: green\">Request accepted</p>";
    } else {
	echo "<p align=\"center\" style=\"color: red\">Request denied (score ".($recaptcha->score)."), please reload the page and try again</p>";
    }

}
?>
