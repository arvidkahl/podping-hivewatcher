<?php

// Monitor hive-watcher.py output continuously for notifications
// It's expected you would run this script like so:
//    python3 -u ./hive-watcher.py --json | php ./podping_watcher.php
//
//


//Monitor hive-watcher.py output continuously
while (1) {

    sleep(1);

    //Vars
    $timestamp = date(DATE_RFC2822);
    $reason = "update";
    $medium = "podcast";
    $version = "";
    $urls = [];

    //Get the incoming podping json payload from STDIN and parse it
    $json = trim(readline());
    $podping = json_decode($json, TRUE);

//    echo "--- $timestamp ---\n " . $json . "\n";

    //Bail on unknown payload schema
    if (!isset($podping['version']) || empty($podping['version'])) {
        continue;
    }

    //Reason code
    //_https://github.com/Podcastindex-org/podping-hivewriter#podping-reasons
    if (isset($podping['reason']) && !empty($podping['reason'])) {
        $reason = $podping['reason'];
    }

    //Medium code
    //_https://github.com/Podcastindex-org/podping-hivewriter#mediums
    if (isset($podping['medium']) && !empty($podping['medium'])) {
        $medium = $podping['medium'];
    }

    //Get the url list from the payload
    //_https://github.com/Podcastindex-org/podping-hivewriter/issues/26
    switch ($podping['version']) {
        case "0.3":
            $version = "0.3";
            $iris = $podping['urls'];
            break;
        case "1.0":
            $version = "1.0";
            $iris = $podping['iris'];
            break;
        case "1.1":
            $version = "1.1";
            $iris = $podping["iris"];
            break;
        default:
            continue 2;
    }

    //Logging - incoming podping banner
//    echo "PODPING(v$version) - $medium - $reason:\n";

    $results = [];
    //Handle each iri
    foreach ($iris as $iri) {
        //Make sure it's a valid iri scheme that we are prepared to handle
        if (stripos($iri, 'http://') !== 0
            && stripos($iri, 'https://') !== 0
        ) {
            continue;
        }

        //Logging
//        echo " -- Poll: [$iri].\n";

        // add to the results
        $results[] = $iri;

        //Attempt to mark the feed for immediate polling
        //$result = poll_feed($iri);
    }

    //logging - visual break

    echo "Reporting results to podping endpoint: " . json_encode($results) . "\n";

    // send a POST request to the podping endpoint at https://podscan.fm/-/podping, containing the results in a json array called "urls

    try {
    // create a new cURL resource
    $ch = curl_init();

    // get REPORT_URL from environment
    $report_url = getenv('REPORT_URL');

    // set URL and other appropriate options
    curl_setopt($ch, CURLOPT_URL, $report_url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(["urls" => $results]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));

    curl_exec($ch);

    // close cURL resource, and free up system resources
    curl_close($ch);
    } catch (Exception $e) {
        echo "Error reporting: " . $e->getMessage() . "\n";
    }
}

//Exit
echo "Exiting.\n";
