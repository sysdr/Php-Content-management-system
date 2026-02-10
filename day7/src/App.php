<?php
$baseDir = dirname(__DIR__);
require_once __DIR__ . '/ResourceWatcher.php';

$resourceLog = $baseDir . '/logs/resource_events.log';
$appLog = $baseDir . '/logs/app_events.log';

// Clear previous resource log for a clean run
if (file_exists($resourceLog)) {
    unlink($resourceLog);
}

function log_message(string $message, string $appLog): void {
    $logDir = dirname($appLog);
    if (!is_dir($logDir)) {
        mkdir($logDir, 0777, true);
    }
    file_put_contents($appLog, date('[Y-m-d H:i:s]') . " " . $message . PHP_EOL, FILE_APPEND);
}

function processRequestSimulation(int $requestId, string $resourceLog, string $appLog): void {
    log_message("--- Simulating Request #${requestId} ---", $appLog);
    echo "--- Simulating Request #${requestId} ---\n";

    $watcher = new ResourceWatcher("Request-{$requestId}", $resourceLog);
    $watcher->doWork();

    log_message("--- Request #${requestId} Simulation End ---", $appLog);
    echo "--- Request #${requestId} Simulation End ---\n\n";
}

log_message("Application started.", $appLog);
echo "Application started. Simulating multiple requests...\n\n";

for ($i = 1; $i <= 3; $i++) {
    processRequestSimulation($i, $resourceLog, $appLog);
    sleep(1);
}

log_message("Main script finished.", $appLog);
echo "Main script finished. Check logs/resource_events.log and logs/app_events.log for details.\n";
