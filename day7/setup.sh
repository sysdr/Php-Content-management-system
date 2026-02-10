#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# --- Configuration ---
PROJECT_NAME="HighScalePHPCMS_ResourceCleanup"
SRC_DIR="src"
LOG_DIR="logs"
DATA_DIR="data"
PUBLIC_DIR="public"
APP_FILE="${SRC_DIR}/App.php"
RESOURCE_WATCHER_FILE="${SRC_DIR}/ResourceWatcher.php"
LOG_FILE="${LOG_DIR}/resource_events.log"
STATS_FILE="${DATA_DIR}/stats.json"

# --- Setup Project & File Structure ---
echo "Setting up project directory: ${PROJECT_NAME}..."
mkdir -p "${SRC_DIR}" "${LOG_DIR}" "${DATA_DIR}" "${PUBLIC_DIR}" "tests"

# --- Generate Source Code: ResourceWatcher.php ---
echo "Generating ${RESOURCE_WATCHER_FILE}..."
cat << 'EOF' > "${RESOURCE_WATCHER_FILE}"
<?php

class ResourceWatcher
{
    private string $resourceIdentifier;
    private bool $isResourceActive = false;
    private string $logFilePath;

    public function __construct(string $identifier, string $logFilePath = 'logs/resource_events.log')
    {
        $this->resourceIdentifier = $identifier;
        $this->logFilePath = $logFilePath;
        $this->acquireResource();
    }

    private function acquireResource(): void
    {
        // Simulate acquiring a resource (e.g., opening a file, connecting to DB)
        // In a real system, this would be a real connection/handle.
        $this->isResourceActive = true;
        $this->log("Resource '{$this->resourceIdentifier}' acquired.");
    }

    public function doWork(): string
    {
        if (!$this->isResourceActive) {
            return "Error: Resource '{$this->resourceIdentifier}' is not active.";
        }
        $this->log("Resource '{$this->resourceIdentifier}' performing work.");
        return "Work done by: {$this->resourceIdentifier}";
    }

    public function __destruct()
    {
        // This is crucial: ensure resource is released if not explicitly done
        if ($this->isResourceActive) {
            $this->isResourceActive = false;
            $this->log("Resource '{$this->resourceIdentifier}' automatically released via __destruct.");
        }
    }

    private function log(string $message): void
    {
        if (!is_dir(dirname($this->logFilePath))) {
            mkdir(dirname($this->logFilePath), 0777, true);
        }
        file_put_contents($this->logFilePath, date('[Y-m-d H:i:s]') . " " . $message . PHP_EOL, FILE_APPEND);
    }
}
EOF

# --- Generate Source Code: App.php ---
echo "Generating ${APP_FILE}..."
cat << 'EOF' > "${APP_FILE}"
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
EOF

# --- Initialize data/stats.json for dashboard ---
echo "Initializing ${STATS_FILE}..."
echo '{"request_runs":0,"last_destruct_calls":0,"total_requests_simulated":0}' > "${STATS_FILE}"

# --- Generate public/run_demo.php ---
echo "Generating ${PUBLIC_DIR}/run_demo.php..."
cat << 'RUNDEMO' > "${PUBLIC_DIR}/run_demo.php"
<?php
header('Content-Type: application/json; charset=utf-8');
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$logFile = $base . '/logs/resource_events.log';
@unlink($logFile);
$cmd = 'cd ' . escapeshellarg($base) . ' && php ' . escapeshellarg($base . '/src/App.php') . ' 2>&1';
$output = (string)shell_exec($cmd);
$stats['request_runs'] = ($stats['request_runs'] ?? 0) + 1;
$stats['total_requests_simulated'] = ($stats['request_runs'] ?? 0) * 3;
$destructCount = 0;
if (is_file($logFile)) {
    $destructCount = (int)preg_match_all('/automatically released via __destruct/', file_get_contents($logFile));
}
$stats['last_destruct_calls'] = $destructCount;
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
RUNDEMO

# --- Generate public/dashboard.php ---
echo "Generating ${PUBLIC_DIR}/dashboard.php..."
cat << 'DASH' > "${PUBLIC_DIR}/dashboard.php"
<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$requestRuns = (int)($stats['request_runs'] ?? 0);
$destructCalls = (int)($stats['last_destruct_calls'] ?? 0);
$totalRequests = (int)($stats['total_requests_simulated'] ?? 0);
if (!empty($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'request_runs' => $requestRuns,
        'last_destruct_calls' => $destructCalls,
        'total_requests_simulated' => $totalRequests
    ]);
    exit;
}
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Resource Cleanup — Dashboard (Day 7)</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: 'Segoe UI', system-ui, -apple-system, sans-serif; margin: 0; padding: 0; background: linear-gradient(160deg, #0d2137 0%, #1a3a52 40%, #0f2d44 100%); min-height: 100vh; color: #e8eef2; line-height: 1.5; }
    .container { max-width: 920px; margin: 0 auto; padding: 1.5rem; }
    header { background: linear-gradient(90deg, #0e639c 0%, #1177bb 50%, #0d5689 100%); color: #fff; padding: 1.35rem 0; margin-bottom: 1.5rem; box-shadow: 0 4px 20px rgba(14, 99, 156, 0.4); }
    header h1 { margin: 0 0 0.3rem; font-size: 1.65rem; font-weight: 700; letter-spacing: 0.02em; }
    header p { margin: 0; opacity: 0.92; font-size: 0.95rem; }
    section { background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.12); border-radius: 12px; padding: 1.35rem 1.6rem; margin-bottom: 1.25rem; }
    section h2 { margin: 0 0 1rem; font-size: 1.05rem; font-weight: 600; color: #7dd3fc; text-transform: uppercase; letter-spacing: 0.06em; }
    .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
    .metric-card { border-radius: 10px; padding: 1.15rem; text-align: center; border: 1px solid rgba(255, 255, 255, 0.1); }
    .metric-card:nth-child(1) { background: linear-gradient(145deg, rgba(34, 197, 94, 0.22), rgba(34, 197, 94, 0.06)); border-color: rgba(34, 197, 94, 0.45); }
    .metric-card:nth-child(2) { background: linear-gradient(145deg, rgba(251, 191, 36, 0.22), rgba(251, 191, 36, 0.06)); border-color: rgba(251, 191, 36, 0.45); }
    .metric-card:nth-child(3) { background: linear-gradient(145deg, rgba(168, 85, 247, 0.22), rgba(168, 85, 247, 0.06)); border-color: rgba(168, 85, 247, 0.45); }
    .metric-card h3 { margin: 0 0 0.5rem; font-size: 0.8rem; font-weight: 600; color: rgba(255, 255, 255, 0.8); text-transform: uppercase; letter-spacing: 0.04em; }
    .metric-value { font-size: 2rem; font-weight: 700; font-variant-numeric: tabular-nums; }
    .metric-card:nth-child(1) .metric-value { color: #22c55e; }
    .metric-card:nth-child(2) .metric-value { color: #fbbf24; }
    .metric-card:nth-child(3) .metric-value { color: #a855f7; }
    .metric-note { font-size: 0.72rem; color: rgba(255, 255, 255, 0.5); margin-top: 0.35rem; }
    .ops-panel { display: flex; flex-wrap: wrap; align-items: center; gap: 1rem; padding: 0.5rem 0; }
    .ops-desc { flex: 1; min-width: 200px; font-size: 0.9rem; color: rgba(255, 255, 255, 0.75); }
    .ops-trigger { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.6rem 1rem; background: linear-gradient(135deg, #059669, #047857); color: #fff; border: none; border-radius: 8px; font-size: 0.9rem; font-weight: 600; cursor: pointer; text-decoration: none; transition: transform 0.12s, box-shadow 0.12s; box-shadow: 0 2px 8px rgba(5, 150, 105, 0.35); }
    .ops-trigger:hover { transform: translateY(-2px); box-shadow: 0 4px 14px rgba(5, 150, 105, 0.45); }
    .ops-trigger:active { transform: translateY(0); }
    .ops-trigger:disabled, .ops-trigger.loading { opacity: 0.7; cursor: wait; transform: none; }
    .ops-trigger .icon { font-size: 1.1rem; }
    .ops-status { margin-top: 0.75rem; min-height: 1.25rem; font-size: 0.9rem; color: rgba(255, 255, 255, 0.7); }
    .ops-status.ok { color: #22c55e; }
    .ops-status.err { color: #f87171; }
  </style>
</head>
<body>
  <header><div class="container"><h1>Resource Cleanup — Dashboard (Day 7)</h1><p>Simulate request lifecycle and __destruct cleanup. Trigger a run below to refresh metrics.</p></div></header>
  <div class="container">
    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card"><h3>Demo runs</h3><div class="metric-value" id="metric-runs"><?= $requestRuns ?></div><div class="metric-note">Cycles executed</div></div>
        <div class="metric-card"><h3>Destruct calls (last run)</h3><div class="metric-value" id="metric-destruct"><?= $destructCalls ?></div><div class="metric-note">Resources released via __destruct</div></div>
        <div class="metric-card"><h3>Total requests simulated</h3><div class="metric-value" id="metric-total"><?= $totalRequests ?></div><div class="metric-note">3 requests per cycle</div></div>
      </div>
    </section>
    <section>
      <h2>Trigger simulation</h2>
      <div class="ops-panel">
        <div class="ops-desc">Run one resource-cleanup cycle (3 simulated requests). Each request acquires a resource and releases it via <code>__destruct</code> when the handler ends.</div>
        <a href="#" role="button" id="op-trigger" class="ops-trigger" aria-label="Execute resource cleanup simulation"><span class="icon">▶</span><span>Execute cycle</span></a>
      </div>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
    </section>
  </div>
  <script>
(function() {
  var origin = window.location.origin || 'http://127.0.0.1:8000';
  var statusEl = document.getElementById('ops-status');
  var triggerEl = document.getElementById('op-trigger');
  function setStatus(msg, type) { statusEl.textContent = msg || ''; statusEl.className = 'ops-status' + (type === 'ok' ? ' ok' : type === 'err' ? ' err' : ''); }
  function fetchStats() { return fetch(origin + '/dashboard.php?json=1').then(function(r) { return r.ok ? r.json() : {}; }).catch(function() { return {}; }); }
  function refreshMetrics() { fetchStats().then(function(s) { document.getElementById('metric-runs').textContent = s.request_runs != null ? s.request_runs : 0; document.getElementById('metric-destruct').textContent = s.last_destruct_calls != null ? s.last_destruct_calls : 0; document.getElementById('metric-total').textContent = s.total_requests_simulated != null ? s.total_requests_simulated : 0; }); }
  triggerEl.addEventListener('click', function(e) { e.preventDefault(); if (triggerEl.classList.contains('loading')) return; triggerEl.classList.add('loading'); triggerEl.setAttribute('aria-busy', 'true'); setStatus('Running simulation…'); fetch(origin + '/run_demo.php').then(function(r) { return r.json(); }).then(function(d) { if (d.ok) { setStatus('Cycle complete. Metrics updated.', 'ok'); refreshMetrics(); } else { setStatus(d.error || 'Error', 'err'); } }).catch(function() { setStatus('Request failed.', 'err'); }).finally(function() { triggerEl.classList.remove('loading'); triggerEl.removeAttribute('aria-busy'); }); });
  refreshMetrics();
})();
  </script>
</body>
</html>
DASH

# --- Generate start.sh ---
echo "Generating start.sh..."
cat << 'START' > start.sh
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
PHP_BIN=""
for p in php /usr/bin/php /usr/local/bin/php; do
  if command -v "$p" &>/dev/null && "$p" -v &>/dev/null 2>&1; then PHP_BIN="$p"; break; fi
done
[ -z "$PHP_BIN" ] && command -v php &>/dev/null && PHP_BIN="php"
if [ -z "$PHP_BIN" ]; then
  echo "PHP not found. Please install PHP or add it to PATH."
  exit 1
fi
if fuser "8000/tcp" >/dev/null 2>&1; then
  echo "Port 8000 already in use. Run stop.sh first or use another port."
  exit 1
fi
nohup $PHP_BIN -S 0.0.0.0:8000 -t public > /dev/null 2>&1 &
sleep 1
if fuser "8000/tcp" >/dev/null 2>&1; then
  echo "Started PHP server on port 8000. Dashboard: http://127.0.0.1:8000/dashboard.php"
else
  echo "Failed to start PHP server on port 8000."
  exit 1
fi
START
chmod +x start.sh

# --- Generate stop.sh ---
echo "Generating stop.sh..."
cat << 'STOP' > stop.sh
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
for port in 8000; do
  if fuser "${port}/tcp" >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
    echo "Stopped process on port ${port}."
  fi
done
STOP
chmod +x stop.sh

# --- Generate tests/run_tests.sh ---
echo "Generating tests/run_tests.sh..."
cat << 'TEST' > tests/run_tests.sh
#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
BASE="http://127.0.0.1:8000"
echo "=== Day7 Resource Cleanup tests ==="
echo "Test 1: src/ResourceWatcher.php exists..."
[ -f src/ResourceWatcher.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: src/App.php exists..."
[ -f src/App.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: public/dashboard.php exists..."
[ -f public/dashboard.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: public/run_demo.php exists..."
[ -f public/run_demo.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 6: Direct PHP run produces destruct log..."
if command -v php &>/dev/null; then
  rm -f logs/resource_events.log logs/app_events.log
  php src/App.php >/dev/null 2>&1
  [ -f logs/resource_events.log ] && grep -q "automatically released via __destruct" logs/resource_events.log && echo "OK" || { echo "FAIL"; exit 1; }
else
  echo "SKIP (php not in PATH)"
fi
echo "Test 7: Dashboard (if server running) loads..."
code=$(curl -sf -o /tmp/d7_dash.html -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "OK" || { echo "SKIP (server not running — start with ./start.sh)"; }
if [ "$code" = "200" ]; then
  echo "Test 8: Dashboard JSON endpoint..."
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "request_runs" && echo "$stats" | grep -q "last_destruct_calls" && echo "OK" || { echo "FAIL"; exit 1; }
  echo "Test 9: Run demo updates metrics..."
  curl -sf "$BASE/run_demo.php" > /dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  runs=$(echo "$stats2" | grep -o '"request_runs":[0-9]*' | cut -d: -f2)
  [ -n "$runs" ] && [ "$runs" -ge 1 ] && echo "OK (request_runs=$runs)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
TEST
chmod +x tests/run_tests.sh

# --- Build/Test/Run (No Docker) ---
echo "--- Running PHP application (without Docker) ---"
echo "--------------------------------------------------"
php "${APP_FILE}"
PHP_EXIT_CODE=$?

if [ $PHP_EXIT_CODE -eq 0 ]; then
    echo -e "\n--- Functional Test & Verification (without Docker) ---"
    echo "Verification: Checking log file for destructor calls..."
    DESTRUCT_COUNT=0
    [ -f "${LOG_FILE}" ] && DESTRUCT_COUNT=$(grep -c "automatically released via __destruct" "${LOG_FILE}" 2>/dev/null) || true
    EXPECTED_COUNT=3

    if [ "$DESTRUCT_COUNT" -eq "$EXPECTED_COUNT" ]; then
        echo "SUCCESS: Found ${DESTRUCT_COUNT} expected destructor calls. Resource cleanup is working as expected!"
    else
        echo "FAILURE: Expected ${EXPECTED_COUNT} destructor calls, but found ${DESTRUCT_COUNT}. Check ${LOG_FILE} for errors."
    fi
    # Seed dashboard stats so metrics are non-zero after setup
    echo "Seeding dashboard stats (non-zero metrics)..."
    echo "{\"request_runs\":1,\"last_destruct_calls\":${DESTRUCT_COUNT},\"total_requests_simulated\":3}" > "${STATS_FILE}"
else
    echo "ERROR: PHP application exited with code ${PHP_EXIT_CODE}."
fi

# --- Docker Integration (Optional) ---
echo -e "\n--- Docker integration (placeholder for future) ---"
echo "For now, __destruct is demonstrated via CLI PHP and dashboard demo."

echo -e "\n--- Setup Complete ---"
echo "Generated: ${APP_FILE}, ${RESOURCE_WATCHER_FILE}, ${PUBLIC_DIR}/dashboard.php, ${PUBLIC_DIR}/run_demo.php, start.sh, stop.sh, tests/run_tests.sh"
echo "Start server: ./start.sh  |  Dashboard: http://127.0.0.1:8000/dashboard.php"
echo "Review '${LOG_FILE}' and '${LOG_DIR}/app_events.log' for detailed output."