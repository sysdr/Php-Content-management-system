<?php
header('Content-Type: application/json; charset=utf-8');
$type = isset($_GET['type']) ? $_GET['type'] : (isset($_POST['type']) ? $_POST['type'] : '');
if (!in_array($type, ['direct', 'docker'], true)) {
    echo json_encode(['ok' => false, 'error' => 'Use type=direct or type=docker']);
    exit;
}
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];

if ($type === 'direct') {
    $cmd = 'php ' . escapeshellarg($base . '/src/leaky_app.php') . ' 2>&1';
    $output = shell_exec($cmd);
    $stats['direct_runs'] = ($stats['direct_runs'] ?? 0) + 1;
} else {
    $cmd = 'docker run --rm php-leak-detector 2>&1';
    $output = shell_exec($cmd);
    $stats['docker_runs'] = ($stats['docker_runs'] ?? 0) + 1;
}

if (preg_match('/Peak Memory:\s*([\d.]+)\s*MB/', (string)$output, $m)) {
    $stats['last_peak_memory_mb'] = (float)$m[1];
}
if (preg_match('/Final Memory:\s*([\d.]+)\s*MB/', (string)$output, $m)) {
    $stats['last_final_memory_mb'] = (float)$m[1];
}
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
