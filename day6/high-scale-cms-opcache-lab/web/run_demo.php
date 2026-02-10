<?php
header('Content-Type: application/json; charset=utf-8');
$type = isset($_GET['type']) ? $_GET['type'] : (isset($_POST['type']) ? $_POST['type'] : '');
if (!in_array($type, ['web', 'cli'], true)) {
    echo json_encode(['ok' => false, 'error' => 'Use type=web or type=cli']);
    exit;
}
$dataDir = __DIR__ . '/data';
$statsFile = $dataDir . '/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];

if ($type === 'web') {
    $stats['web_requests'] = ($stats['web_requests'] ?? 0) + 1;
    if (!is_dir($dataDir)) {
        @mkdir($dataDir, 0755, true);
    }
    @file_put_contents($statsFile, json_encode($stats), LOCK_EX);
    $url = 'http://nginx/index.php?json=1';
    $ctx = stream_context_create(['http' => ['timeout' => 120]]);
    $raw = @file_get_contents($url, false, $ctx);
    if ($raw) {
        $data = @json_decode($raw, true);
        if (isset($data['execution_time_ms'])) {
            $stats['last_web_time_ms'] = (float)$data['execution_time_ms'];
        }
    }
} else {
    $stats['cli_runs'] = ($stats['cli_runs'] ?? 0) + 1;
    if (!is_dir($dataDir)) {
        @mkdir($dataDir, 0755, true);
    }
    @file_put_contents($statsFile, json_encode($stats), LOCK_EX);
    $output = [];
    exec('php /var/www/cli/cpu_intensive_task.php 2>&1', $output);
    $output = implode("\n", $output);
    if (preg_match('/Execution Time:\s*([\d.]+)\s*ms/', $output, $m)) {
        $stats['last_cli_time_s'] = (float)$m[1] / 1000.0;
    } elseif (preg_match('/Execution Time:\s*([\d.]+)\s*s/', $output, $m)) {
        $stats['last_cli_time_s'] = (float)$m[1];
    }
}

if (function_exists('opcache_get_status')) {
    $status = @opcache_get_status(false);
    if ($status && isset($status['opcache_statistics']['num_cached_scripts'])) {
        $stats['opcache_cached_scripts'] = (int)$status['opcache_statistics']['num_cached_scripts'];
    }
    if ($status && isset($status['jit'])) {
        $stats['jit_enabled'] = !empty($status['jit']['enabled']);
    }
}

if (!is_dir($dataDir)) {
    @mkdir($dataDir, 0755, true);
}
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
