<?php

// --------------------------------------------------------------------------------------
// DB Settings

$DB_HOST = "localhost";
$DB_USER = "comics";
$DB_PASS = "comics";
$DB_NAME = "comics";

// --------------------------------------------------------------------------------------
// Helpers

function fatalError($reason)
{
    $response = array("error" => $reason);
    header("Content-Type: application/json");
    print(json_encode($response));
    exit();
}

// --------------------------------------------------------------------------------------
// ReadState

class ReadState
{
    // User input
    var $actions;
    var $path;
    var $user;

    // DB Info
    var $ignoredList;
    var $progressTable;
    var $ratingsTable;

    // Manifest info
    var $manifest;
    var $issues;   // map of [dir -> flat list of issues in all subdirs]
    var $children; // map of [dir -> direct children (with type: issue/index)]

    // Response info
    var $response;

    // Performance
    var $startTime;

    function ReadState()
    {
        $this->startTime = microtime(true);

        $this->user = $_SERVER['REMOTE_USER'];
        if(!$this->user) {
            fatalError("no user");
        }

        $this->actions = json_decode(file_get_contents('php://input'), true);
        if(!$this->actions) {
            $this->actions = array();
        }

        if(array_key_exists($this->path, $_GET)) {
            $this->path = $_GET['p'];
        }
        if(!$this->path) {
            $this->path = "";
        }

        $this->response = array();
        $this->loadManifest();
    }

    function loadManifest()
    {
        //$start = microtime(true);
        $json = file_get_contents("server.crackers");
        $this->manifest = json_decode($json, true);
        //$diff = 1000 * (microtime(true) - $start);
        //print("parsed in ".$diff." ms");

        $this->issues = $this->manifest["issues"];
        $this->children = $this->manifest["children"];
    }

    function loadProgressFromDB()
    {
        global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME;
        $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
        if($conn->connect_error) {
            fatalError("Connection failed: " + $conn->connect_error);
        }

        $dir = null;
        $page = null;
        $rating = null;
        $ignored = array();
        $this->ignoredList = array();
        $this->progressTable = array();
        $this->ratingsTable = array();

        $stmt = $conn->prepare("select dir from ignored where user=?");
        $stmt->bind_param('s', $this->user);
        $stmt->bind_result($dir);
        $stmt->execute();
        while($stmt->fetch()) {
            array_push($this->ignoredList, $dir);
        }
        $stmt->close();

        $stmt = $conn->prepare("select dir,page from progress where user=?");
        $stmt->bind_param('s', $this->user);
        $stmt->bind_result($dir, $page);
        $stmt->execute();
        while($stmt->fetch()) {
            $this->progressTable[$dir] = $page;
        }
        $stmt->close();

        $stmt = $conn->prepare("select dir,rating from ratings where user=?");
        $stmt->bind_param('s', $this->user);
        $stmt->bind_result($dir, $rating);
        $stmt->execute();
        while($stmt->fetch()) {
            $this->ratingsTable[$dir] = $rating;
        }
        $stmt->close();

        $conn->close();
    }

    function readProgress($e)
    {
        $perc = 0;
        $page = 0;
        $rating = 0;
        $type = $e["type"];
        $dir = $e["dir"];
        if($type == "comic") {
            $pages = (int)$e["pages"];
            if(($pages > 0) && array_key_exists($dir, $this->progressTable))
            {
                $page = (int)$this->progressTable[$dir];
                $perc = min(100, (int)(100 * $page / $pages));
            }
            if(array_key_exists($dir, $this->ratingsTable))
            {
                $rating = (int)$this->ratingsTable[$dir];
            }
        } else {
            if(array_key_exists($dir, $this->issues))
            {
                $issues = $this->issues[$dir];
                $readPages = 0;
                $totalPages = 0;
                $ratingSum = 0;
                $ratingCount = 0;
                foreach($issues as $issue)
                {
                    $dir = $issue["dir"];
                    $totalPages += (int)$issue["pages"];
                    if(array_key_exists($dir, $this->progressTable))
                    {
                        $readPages += (int)$this->progressTable[$dir];
                    }
                    if(array_key_exists($dir, $this->ratingsTable))
                    {
                        $ratingSum += (int)$this->ratingsTable[$dir];
                        $ratingCount++;
                    }
                }
                if($ratingCount > 0)
                {
                    $rating = $ratingSum / $ratingCount;
                }
                if($totalPages > 0) {
                    $perc = min(100, (int)(100 * ($readPages / $totalPages)));
                    if($readPages > 0) {
                        // Don't allow a 0% on something you've read at least one page on.
                        $perc = max(1, $perc);
                    }
                    if($readPages != $totalPages) {
                        // Don't allow a 100% on something you haven't completely read.
                        $perc = min(99, $perc);
                    }
                }
            }
        }
        return array($perc, $page, $rating);
    }

    function processActions()
    {
        global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME;
        // $this->response["actions"] = json_encode($this->actions);

        if(array_key_exists("ignore", $this->actions)) {
            // Trying to toggle ignore

            $currentlyIgnored = false;
            $ignoreDir = $this->actions['ignore'];
            $outputDir = "";

            $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
            if($conn->connect_error) {
                fatalError("Connection failed: " + $conn->connect_error);
            }
            $stmt = $conn->prepare("select dir from ignored where user=? and dir=?");
            $stmt->bind_param('ss', $this->user, $ignoreDir);
            $stmt->bind_result($outputDir);
            if($stmt->execute()) {
                $stmt->fetch();
            }
            if($ignoreDir == $outputDir) {
                $currentlyIgnored = true;
            }
            $this->response['ignored'] = $currentlyIgnored;
            // $this->response['stmt'] = $stmt->error;
            $stmt->close();

            if($currentlyIgnored) {
                $stmt = $conn->prepare("delete from ignored where user=? and dir=?");
                $stmt->bind_param('ss', $this->user, $ignoreDir);
                $stmt->execute();
                // $this->response['stmt'] = $stmt->error;
                $stmt->close();
            } else {
                $stmt = $conn->prepare("insert into ignored (user, dir) VALUES (?, ?)");
                $stmt->bind_param('ss', $this->user, $ignoreDir);
                $stmt->execute();
                // $this->response['stmt'] = $stmt->error;
                $stmt->close();
            }
            $conn->close();
        } else if(array_key_exists("rating", $this->actions)) {
            // Trying to set or unset a rating

            $rating = $this->actions['rating'];
            $dir = $this->actions["dir"];

            $torate = array();
            foreach($this->manifest["flat"] as $issue) {
                if(strpos($issue['dir'], $dir) === 0) {
                    array_push($torate, $issue);
                }
            }
            //$this->response["torate"] = $torate;

            $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
            if($conn->connect_error) {
                fatalError("Connection failed: " + $conn->connect_error);
            }
            if($rating > 0) {
                foreach($torate as $issue) {
                    $issueDir = $issue['dir'];
                    $stmt = $conn->prepare("insert into ratings (user, dir, rating) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE rating=?");
                    $stmt->bind_param('ssii', $this->user, $issueDir, $rating, $rating);
                    $stmt->execute();
                    // $this->response['stmt'] = $stmt->error;
                    $stmt->close();
                }
            } else {
                foreach($torate as $issue) {
                    $issueDir = $issue['dir'];
                    $stmt = $conn->prepare("delete from ratings where user=? and dir=?");
                    $stmt->bind_param('ss', $this->user, $issueDir);
                    $stmt->execute();
                    // $this->response['stmt'] = $stmt->error;
                    $stmt->close();
                }
            }
            $conn->close();
        } else if(array_key_exists("mark", $this->actions) || array_key_exists("unmark", $this->actions)) {
            // Trying to mark as read/unread.

            $mark = true;
            if(array_key_exists("mark", $this->actions)) {
                $dir = $this->actions["mark"];
                $mark = true;
            } else {
                $dir = $this->actions["unmark"];
                $mark = false;
            }

            $tomark = array();
            foreach($this->manifest["flat"] as $issue) {
                if(strpos($issue['dir'], $dir) === 0) {
                    array_push($tomark, $issue);
                }
            }
            //$this->response["tomark"] = $tomark;

            $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
            if($conn->connect_error) {
                fatalError("Connection failed: " + $conn->connect_error);
            }
            if($mark) {
                foreach($tomark as $issue) {
                    $page = $issue['pages'];
                    $issueDir = $issue['dir'];
                    $stmt = $conn->prepare("insert into progress (user, dir, page) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE page=?");
                    $stmt->bind_param('ssii', $this->user, $issueDir, $page, $page);
                    $stmt->execute();
                    // $this->response['stmt'] = $stmt->error;
                    $stmt->close();
                }
            } else {
                foreach($tomark as $issue) {
                    $issueDir = $issue['dir'];
                    $stmt = $conn->prepare("delete from progress where user=? and dir=?");
                    $stmt->bind_param('ss', $this->user, $issueDir);
                    $stmt->execute();
                    // $this->response['stmt'] = $stmt->error;
                    $stmt->close();
                }
            }
            $conn->close();
        } else if(array_key_exists("page", $this->actions)) {
            // Trying to update the current page.

            $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
            if($conn->connect_error) {
                fatalError("Connection failed: " + $conn->connect_error);
            }
            $dir = $this->actions["dir"];
            $page = $this->actions['page'];
            $stmt = $conn->prepare("insert into progress (user, dir, page) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE page=?");
            $stmt->bind_param('ssii', $this->user, $dir, $page, $page);
            $stmt->execute();
            // $this->response['stmt'] = $stmt->error;
            $stmt->close();
            $conn->close();
        }
    }

    function processProgress()
    {
        $this->loadProgressFromDB();

        if(!array_key_exists("skip", $this->actions)) {
            $this->response["children"] = $this->children;
            // $this->response["exists"] = $this->manifest["exists"];
            $this->response["page"] = array();

            foreach($this->response["children"] as $dir => &$list)
            {
                foreach($list as &$e)
                {
                    list ($perc, $page, $rating) = $this->readProgress($e);
                    foreach($this->ignoredList as $ignored) {
                        if(strpos($e['dir'], $ignored) === 0) {
                            $perc = -1;
                            break;
                        }
                    }

                    $e["perc"] = $perc;
                    $e["rating"] = $rating;
                    if($e["type"] === "comic") {
                        $e["page"] = $page;
                        $this->response["page"][$e['dir']] = $page;
                    }
                }
            }
        }
    }

    function respond()
    {
        header("Content-Type: application/json");
        $this->response["ms"] = 100 * (microtime(true) - $this->startTime);
        print(json_encode($this->response, JSON_UNESCAPED_SLASHES));
    }
}

// --------------------------------------------------------------------------------------
// main

$readState = new ReadState();
$readState->processActions();
$readState->processProgress();
$readState->respond();
