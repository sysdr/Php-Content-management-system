<?php
// web/index.php - CPU-intensive script for web access

function fibonacci($n) {
    if ($n <= 1) {
        return $n;
    }
    return fibonacci($n - 1) + fibonacci($n - 2);
}

$start_time = microtime(true);
$result = fibonacci(35); // A moderately CPU-intensive calculation
$end_time = microtime(true);

$execution_time = round(($end_time - $start_time) * 1000, 2); // in ms

if (!empty($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['execution_time_ms' => $execution_time, 'result' => $result, 'php_version' => PHP_VERSION]);
    exit;
}

echo "<h1>OPcache & JIT Lab - Web Demo</h1>";
echo "<p>Fibonacci(35) calculated: <strong>" . $result . "</strong></p>";
echo "<p>Execution Time: <strong>" . $execution_time . " ms</strong></p>";
echo "<p>PHP Version: " . PHP_VERSION . "</p>";
echo "<p>OPcache status: <a href='opcache-status.php'>View</a></p>";
?>
