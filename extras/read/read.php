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
    var $progressTable;

    // Manifest info
    var $manifest;
    var $issues;   // map of [dir -> flat list of issues in all subdirs]
    var $children; // map of [dir -> direct children (with type: issue/index)]

    // Response info
    var $response;

    function ReadState()
    {
        $this->user = $_SERVER['REMOTE_USER'];
        if(!$this->user) {
            fatalError("no user");
        }

        $this->actions = json_decode(file_get_contents('php://input'), true);
        if(!$this->actions) {
            $this->actions = array();
        }

        $this->path = $_GET['p'];
        if(!$this->path) {
            $this->path = "";
        }

        $this->response = array();
        $this->loadManifest();
    }

    function loadManifest()
    {
        //$start = microtime(true);
        $json = file_get_contents("manifest.crackers");
        $this->manifest = json_decode($json, true);
        //$diff = 1000 * (microtime(true) - $start);
        //print("parsed in ".$diff." ms");

        $this->issues = $this->manifest["issues"];
        $this->children = $this->manifest["children"];
    }

    function loadProgressFromDB($user)
    {
        global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME;
        $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
        if($conn->connect_error) {
            fatalError("Connection failed: " + $conn->connect_error);
        }

        $dir = null;
        $page = null;
        $stmt = $conn->prepare("select dir,page from progress where user=?");
        $stmt->bind_param('s', $this->user);
        $stmt->bind_result($dir, $page);
        $stmt->execute();

        $this->progressTable = array();
        while($stmt->fetch()) {
            $this->progressTable[$dir] = $page;
        }

        $stmt->close();
        $conn->close();
    }

    function readPercent($e)
    {
        $perc = 0;
        $type = $e["type"];
        $dir = $e["dir"];
        if($type == "issue") {
            $pages = (int)$e["pages"];
            if(($pages > 0) && array_key_exists($dir, $this->progressTable))
            {
                $perc = min(100, (int)(100 * ((int)$this->progressTable[$dir]) / $pages));
            }
        } else {
            if(array_key_exists($dir, $this->issues))
            {
                $issues = $this->issues[$dir];
                $readPages = 0;
                $totalPages = 0;
                foreach($issues as $issue)
                {
                    $dir = $issue["dir"];
                    $totalPages += (int)$issue["pages"];
                    if(array_key_exists($dir, $this->progressTable))
                    {
                        $readPages += (int)$this->progressTable[$dir];
                    }
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
        return $perc;
    }

    function processActions()
    {
        global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME;
        // $this->response["actions"] = json_encode($this->actions);

        if(array_key_exists("mark", $this->actions) || array_key_exists("unmark", $this->actions)) {
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
        } else if(array_key_exists("pos", $this->actions)) {
            // requesting current position in a comic.
            $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
            if($conn->connect_error) {
                fatalError("Connection failed: " + $conn->connect_error);
            }
            $page = 0;
            $stmt = $conn->prepare("select page from progress where user=? and dir=?");
            $stmt->bind_param('ss', $this->user, $this->path);
            $stmt->bind_result($page);
            if($stmt->execute()) {
                $stmt->fetch();
            }
            // $this->response['stmt'] = $stmt->error;
            $stmt->close();
            $conn->close();
            $this->response['pos'] = $page;
        } else if(array_key_exists("page", $this->actions)) {
            $conn = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
            if($conn->connect_error) {
                fatalError("Connection failed: " + $conn->connect_error);
            }
            $page = $this->actions['page'];
            $stmt = $conn->prepare("insert into progress (user, dir, page) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE page=?");
            $stmt->bind_param('ssii', $this->user, $this->path, $page, $page);
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
            if(!array_key_exists($this->path, $this->children)) {
                fatalError("Unknown path: ".$this->path);
            }

            $this->response["read"] = array();
            $children = $this->children[$this->path];
            foreach($children as $e)
            {
                $perc = $this->readPercent($e);
                $this->response["read"][$e["dir"]] = array(
                    "progress" => $perc,
                );
            }
        }
    }

    function respond()
    {
        header("Content-Type: application/json");
        print(json_encode($this->response));
    }
}

// --------------------------------------------------------------------------------------
// main

$readState = new ReadState();
$readState->processActions();
$readState->processProgress();
$readState->respond();
