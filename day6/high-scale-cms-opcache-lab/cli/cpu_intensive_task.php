<?php
// cli/cpu_intensive_task.php - CPU-intensive script for CLI

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

echo "--- OPcache & JIT Lab - CLI Demo ---\n";
echo "Fibonacci(35) calculated: " . $result . "\n";
echo "Execution Time: " . $execution_time . " ms\n";
echo "PHP Version: " . PHP_VERSION . "\n";

// Display OPcache status for CLI, if enabled
if (function_exists('opcache_get_status') && ini_get('opcache.enable_cli')) {
    echo "OPcache CLI is ENABLED.\n";
    $status = opcache_get_status(false);
    echo "Cached files: " . count($status['scripts']) . "\n";
    if (isset($status['jit'])) {
        echo "JIT enabled: " . ($status['jit']['enabled'] ? 'Yes' : 'No') . "\n";
    }
} else {
    echo "OPcache CLI is DISABLED (or function not available).\n";
}
echo "-------------------------------------\n";
?>
