<?php

// perhaps adjust these paths
const GUESTBOOK_FILE = "/data/ngill/guestbook.jsonl";
const RATE_LIMIT_FILE = "/data/ngill/ratelimit.json";
const RATE_LIMIT_SECONDS = 30;

function rate_limit(): bool {
    $ip = $_SERVER['REMOTE_ADDR'];

    if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 | FILTER_FLAG_IPV6)) {
        return false;
    }
    
    $fp = fopen(RATE_LIMIT_FILE, "c+");
    if (!$fp) {
        return false;
    }

    flock($fp, LOCK_EX);

    $contents = stream_get_contents($fp);
    $limits = $contents ? json_decode($contents, true) : [];
    if (!is_array($limits)) {
        $limits = [];
    }

    $now = time();

    foreach ($limits as $address => $timestamp) {
        if ($timestamp <= $now - RATE_LIMIT_SECONDS) {
            unset($limits[$address]);
        }
    }

    $last_sub = $limits[$ip] ?? 0;
    if ($last_sub > $now - RATE_LIMIT_SECONDS) {
        flock($fp, LOCK_UN);
        fclose($fp);
        return false;
    }

    $limits[$ip] = $now;

    ftruncate($fp, 0);
    rewind($fp);
    fwrite($fp, json_encode($limits));
    fflush($fp);

    flock($fp, LOCK_UN);
    fclose($fp);

    return true;
}

header("Content-Type: application/json");

$method = $_SERVER["REQUEST_METHOD"];
$path = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);

if ($method === "POST" && $path === "/") {
    $raw = file_get_contents("php://input");

    $message = json_decode($raw, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        http_response_code(400);
        echo json_encode(["error" => "invalid json"]);
        exit;
    }

    if (!array_key_exists("name", $message) ||
        !array_key_exists("message", $message) ||
        !is_string($message["name"]) ||
        !is_string($message["message"])) {

        http_response_code(400);
        echo json_encode(["error" => "invalid json"]);
        exit;
    }

    if (!rate_limit()) {
        http_response_code(429);
        header("Retry-After: " . strval(RATE_LIMIT_SECONDS));
        echo json_encode(["error" => "too many requests"]);
        exit;
    }

    file_put_contents(
        GUESTBOOK_FILE,
        json_encode(
            ["name" => $message["name"], "message" => $message["message"]],
                JSON_UNESCAPED_UNICODE
        ) . "\n",
        FILE_APPEND | LOCK_EX
    );

    echo json_encode(["ok" => true]);
    exit;
}

if ($method === "GET" && $path === "/") {
    $messages = [];

    if (file_exists(GUESTBOOK_FILE)) {
        foreach (file(GUESTBOOK_FILE, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $messages[] = json_decode($line, true);
        }
    }

    echo json_encode($messages, JSON_UNESCAPED_UNICODE);
    exit;
}

http_response_code(404);
echo json_encode(["error" => "not found"]);

?>
