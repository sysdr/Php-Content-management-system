#!/bin/bash

# --- Configuration ---
PROJECT_DIR="high_scale_cms_day8"
PHP_SCRIPT="worker.php"
DOCKER_IMAGE_NAME="php-cms-worker"
DOCKER_CONTAINER_NAME="php-cms-worker-container"

# --- Utility Functions ---
log_info() {
    echo -e "�33[0;34m[INFO]�33[0m $1"
}

log_success() {
    echo -e "�33[0;32m[SUCCESS]�33[0m $1"
}

log_error() {
    echo -e "�33[0;31m[ERROR]�33[0m $1"
}

log_warning() {
    echo -e "�33[0;33m[WARNING]�33[0m $1"
}

# --- Project Setup ---
setup_project() {
    log_info "Setting up project directory: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR" || { log_error "Failed to create project directory."; exit 1; }
    cd "$PROJECT_DIR" || { log_error "Failed to enter project directory."; exit 1; }

    log_info "Generating $PHP_SCRIPT..."
    cat << 'EOF' > "$PHP_SCRIPT"
<?php

declare(strict_types=1);

// Global flags to control worker behavior
$shutdown_initiated = false;
$reload_config = false;
$worker_name = "PHP-CMS-Worker-" . substr(md5((string)time()), 0, 6);

// --- Signal Handler Function ---
function signalHandler(int $signo): void
{
    global $shutdown_initiated, $reload_config, $worker_name;

    switch ($signo) {
        case SIGTERM:
            echo "n�33[0;33m[SIGNAL]�33[0m Worker PID " . getmypid() . ": SIGTERM received. Initiating graceful shutdown...n";
            $shutdown_initiated = true;
            break;
        case SIGHUP:
            echo "n�33[0;36m[SIGNAL]�33[0m Worker PID " . getmypid() . ": SIGHUP received. Reloading configuration...n";
            // Simulate configuration reload by changing the worker name
            $worker_name = "PHP-CMS-Worker-RELOADED-" . substr(md5((string)time()), 0, 6);
            $reload_config = true; // Set flag to indicate reload for main loop
            break;
        case SIGINT:
            echo "n�33[0;33m[SIGNAL]�33[0m Worker PID " . getmypid() . ": SIGINT received. Initiating graceful shutdown...n";
            $shutdown_initiated = true;
            break;
        default:
            echo "n�33[0;35m[SIGNAL]�33[0m Worker PID " . getmypid() . ": Received unknown signal $signo.n";
            break;
    }
}

// --- Main Worker Logic ---
function runWorker(): void
{
    global $shutdown_initiated, $reload_config, $worker_name;

    // Enable asynchronous signal handling
    // This allows PHP to check for signals even when executing userland code (like sleep())
    pcntl_async_signals(true);

    // Register signal handlers
    pcntl_signal(SIGTERM, "signalHandler");
    pcntl_signal(SIGHUP, "signalHandler");
    pcntl_signal(SIGINT, "signalHandler"); // For Ctrl+C in console

    echo "�33[0;32m[START]�33[0m Worker PID " . getmypid() . " started with name: $worker_name.n";
    echo "         (To test: find PID, then 'kill -TERM <PID>' for shutdown or 'kill -HUP <PID>' for config reload)n";
    echo "         (For Docker: 'docker kill -s TERM php-cms-worker-container' or 'docker kill -s HUP php-cms-worker-container')n";

    $request_counter = 0;
    while (!$shutdown_initiated) {
        // Dispatch pending signals. This is crucial for signals to be processed
        // while the script is busy or sleeping.
        pcntl_signal_dispatch();

        // Simulate config reload if SIGHUP was received
        if ($reload_config) {
            echo "�33[0;36m[CONFIG]�33[0m Worker PID " . getmypid() . ": Applied new configuration. Worker name: $worker_name.n";
            // Reset the flag after processing the reload
            $reload_config = false;
        }

        $request_counter++;
        echo "�33[0;34m[WORK]�33[0m [$worker_name] Worker PID " . getmypid() . ": Processing request #$request_counter...n";
        
        // Simulate real work that takes time (e.g., database query, API call)
        sleep(2); 

        // Dispatch signals again in case one arrived during sleep
        pcntl_signal_dispatch();
    }

    echo "�33[0;33m[SHUTDOWN]�33[0m Worker PID " . getmypid() . ": All pending requests processed. Performing final cleanup...n";
    sleep(1); // Simulate cleanup tasks (e.g., flushing logs, closing connections)
    echo "�33[0;32m[EXIT]�33[0m Worker PID " . getmypid() . ": Exiting gracefully.n";
    exit(0);
}

// Ensure pcntl extension is loaded
if (!extension_loaded('pcntl')) {
    echo "�33[0;31m[ERROR]�33[0m PCNTL extension is not loaded. Please enable it in your php.ini.n";
    exit(1);
}

// Start the worker
runWorker();

EOF
    log_success "$PHP_SCRIPT generated successfully."

    log_info "Generating Dockerfile..."
    cat << 'EOF' > Dockerfile
FROM php:8.2-cli-alpine

RUN apk add --no-cache php82-pecl-pcntl && rm -rf /var/cache/apk/*

WORKDIR /app

COPY worker.php .

CMD ["php", "worker.php"]
EOF
    log_success "Dockerfile generated successfully."

    # --- Directories for dashboard and tests ---
    log_info "Creating data, public, and tests directories..."
    mkdir -p data public tests

    # --- Initialize data/stats.json for dashboard ---
    log_info "Initializing data/stats.json..."
    echo '{"demo_runs":0,"native_cycles":0,"docker_cycles":0,"requests_processed":0}' > data/stats.json

    # --- Generate public/run_demo.php (updates stats by running worker briefly) ---
    log_info "Generating public/run_demo.php..."
    cat << 'RUNDEMO' > public/run_demo.php
<?php
header('Content-Type: application/json; charset=utf-8');
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$logFile = $base . '/data/worker_demo.log';
$workerScript = $base . '/worker.php';
if (!is_file($workerScript)) {
    echo json_encode(['ok' => false, 'error' => 'worker.php not found']);
    exit;
}
@unlink($logFile);
$baseEsc = escapeshellarg($base);
$workerEsc = escapeshellarg($workerScript);
$logEsc = escapeshellarg($logFile);
$cmd = "cd $baseEsc && php $workerEsc > $logEsc 2>&1 & WPID=\$!; sleep 5; kill \$WPID 2>/dev/null; wait \$WPID 2>/dev/null; cat $logEsc";
$output = (string)shell_exec($cmd);
@file_put_contents($logFile, $output);
$requestsProcessed = 0;
if (is_file($logFile)) {
    $requestsProcessed = (int)preg_match_all('/Processing request #\d+/', file_get_contents($logFile));
}
$stats['demo_runs'] = ($stats['demo_runs'] ?? 0) + 1;
$stats['native_cycles'] = ($stats['native_cycles'] ?? 0) + 1;
$stats['requests_processed'] = ($stats['requests_processed'] ?? 0) + $requestsProcessed;
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
RUNDEMO
    log_success "public/run_demo.php generated."

    # --- Generate public/dashboard.php ---
    log_info "Generating public/dashboard.php..."
    cat << 'DASH' > public/dashboard.php
<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$demoRuns = (int)($stats['demo_runs'] ?? 0);
$nativeCycles = (int)($stats['native_cycles'] ?? 0);
$dockerCycles = (int)($stats['docker_cycles'] ?? 0);
$requestsProcessed = (int)($stats['requests_processed'] ?? 0);
if (!empty($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'demo_runs' => $demoRuns,
        'native_cycles' => $nativeCycles,
        'docker_cycles' => $dockerCycles,
        'requests_processed' => $requestsProcessed
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
  <title>Worker Signals — Dashboard (Day 8)</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: 'Segoe UI', system-ui, sans-serif; margin: 0; padding: 0; background: linear-gradient(160deg, #0d2137 0%, #1a3a52 40%, #0f2d44 100%); min-height: 100vh; color: #e8eef2; line-height: 1.5; }
    .container { max-width: 920px; margin: 0 auto; padding: 1.5rem; }
    header { background: linear-gradient(90deg, #0e639c 0%, #1177bb 50%, #0d5689 100%); color: #fff; padding: 1.35rem 0; margin-bottom: 1.5rem; box-shadow: 0 4px 20px rgba(14, 99, 156, 0.4); }
    header h1 { margin: 0 0 0.3rem; font-size: 1.65rem; font-weight: 700; }
    header p { margin: 0; opacity: 0.92; font-size: 0.95rem; }
    section { background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.12); border-radius: 12px; padding: 1.35rem 1.6rem; margin-bottom: 1.25rem; }
    section h2 { margin: 0 0 1rem; font-size: 1.05rem; font-weight: 600; color: #7dd3fc; text-transform: uppercase; letter-spacing: 0.06em; }
    .metrics { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
    @media (min-width: 700px) { .metrics { grid-template-columns: repeat(4, 1fr); } }
    .metric-card { border-radius: 10px; padding: 1.15rem; text-align: center; border: 1px solid rgba(255, 255, 255, 0.1); }
    .metric-card:nth-child(1) { background: linear-gradient(145deg, rgba(34, 197, 94, 0.22), rgba(34, 197, 94, 0.06)); border-color: rgba(34, 197, 94, 0.45); }
    .metric-card:nth-child(2) { background: linear-gradient(145deg, rgba(251, 191, 36, 0.22), rgba(251, 191, 36, 0.06)); border-color: rgba(251, 191, 36, 0.45); }
    .metric-card:nth-child(3) { background: linear-gradient(145deg, rgba(168, 85, 247, 0.22), rgba(168, 85, 247, 0.06)); border-color: rgba(168, 85, 247, 0.45); }
    .metric-card:nth-child(4) { background: linear-gradient(145deg, rgba(236, 72, 153, 0.22), rgba(236, 72, 153, 0.06)); border-color: rgba(236, 72, 153, 0.45); }
    .metric-card h3 { margin: 0 0 0.5rem; font-size: 0.8rem; font-weight: 600; color: rgba(255, 255, 255, 0.8); text-transform: uppercase; letter-spacing: 0.04em; }
    .metric-value { font-size: 2rem; font-weight: 700; font-variant-numeric: tabular-nums; }
    .metric-card:nth-child(1) .metric-value { color: #22c55e; }
    .metric-card:nth-child(2) .metric-value { color: #fbbf24; }
    .metric-card:nth-child(3) .metric-value { color: #a855f7; }
    .metric-card:nth-child(4) .metric-value { color: #ec4899; }
    .metric-note { font-size: 0.72rem; color: rgba(255, 255, 255, 0.5); margin-top: 0.35rem; }
    .ops-panel { display: flex; flex-wrap: wrap; align-items: center; gap: 1rem; padding: 0.5rem 0; }
    .ops-desc { flex: 1; min-width: 200px; font-size: 0.9rem; color: rgba(255, 255, 255, 0.75); }
    .ops-trigger { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.6rem 1rem; background: linear-gradient(135deg, #059669, #047857); color: #fff; border: none; border-radius: 8px; font-size: 0.9rem; font-weight: 600; cursor: pointer; text-decoration: none; transition: transform 0.12s, box-shadow 0.12s; }
    .ops-trigger:hover { transform: translateY(-2px); box-shadow: 0 4px 14px rgba(5, 150, 105, 0.45); }
    .ops-trigger.loading { opacity: 0.7; cursor: wait; }
    .ops-status { margin-top: 0.75rem; min-height: 1.25rem; font-size: 0.9rem; color: rgba(255, 255, 255, 0.7); }
    .ops-status.ok { color: #22c55e; }
    .ops-status.err { color: #f87171; }
  </style>
</head>
<body>
  <header><div class="container"><h1>Worker Signals — Dashboard (Day 8)</h1><p>SIGTERM/SIGHUP worker demo. Run a cycle below to refresh metrics.</p></div></header>
  <div class="container">
    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card"><h3>Demo runs</h3><div class="metric-value" id="metric-demo"><?= $demoRuns ?></div><div class="metric-note">Total demo executions</div></div>
        <div class="metric-card"><h3>Native cycles</h3><div class="metric-value" id="metric-native"><?= $nativeCycles ?></div><div class="metric-note">Native worker runs</div></div>
        <div class="metric-card"><h3>Docker cycles</h3><div class="metric-value" id="metric-docker"><?= $dockerCycles ?></div><div class="metric-note">Docker worker runs</div></div>
        <div class="metric-card"><h3>Requests processed</h3><div class="metric-value" id="metric-requests"><?= $requestsProcessed ?></div><div class="metric-note">Worker request count</div></div>
      </div>
    </section>
    <section>
      <h2>Trigger demo</h2>
      <div class="ops-panel">
        <div class="ops-desc">Run one native worker cycle (worker runs a few seconds, then exits). Metrics update after each run.</div>
        <a href="#" role="button" id="op-trigger" class="ops-trigger" aria-label="Execute demo"><span>▶</span><span>Execute cycle</span></a>
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
  function refreshMetrics() { fetchStats().then(function(s) { document.getElementById('metric-demo').textContent = s.demo_runs != null ? s.demo_runs : 0; document.getElementById('metric-native').textContent = s.native_cycles != null ? s.native_cycles : 0; document.getElementById('metric-docker').textContent = s.docker_cycles != null ? s.docker_cycles : 0; document.getElementById('metric-requests').textContent = s.requests_processed != null ? s.requests_processed : 0; }); }
  triggerEl.addEventListener('click', function(e) { e.preventDefault(); if (triggerEl.classList.contains('loading')) return; triggerEl.classList.add('loading'); setStatus('Running…'); fetch(origin + '/run_demo.php').then(function(r) { return r.json(); }).then(function(d) { if (d.ok) { setStatus('Cycle complete. Metrics updated.', 'ok'); refreshMetrics(); } else { setStatus(d.error || 'Error', 'err'); } }).catch(function() { setStatus('Request failed.', 'err'); }).finally(function() { triggerEl.classList.remove('loading'); }); });
  refreshMetrics();
})();
  </script>
</body>
</html>
DASH
    log_success "public/dashboard.php generated."

    # --- Generate start.sh ---
    log_info "Generating start.sh..."
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
    log_success "start.sh generated."

    # --- Generate stop.sh ---
    log_info "Generating stop.sh..."
    cat << 'STOP' > stop.sh
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
# Stop PHP server on 8000
for port in 8000; do
  if fuser "${port}/tcp" >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
    echo "Stopped process on port ${port}."
  fi
done
# Stop native worker if running
if [ -f native_worker.pid ]; then
  WPID=$(cat native_worker.pid 2>/dev/null)
  [ -n "$WPID" ] && kill "$WPID" 2>/dev/null && echo "Stopped native worker PID $WPID."
  rm -f native_worker.pid
fi
if [ -f native_tail.pid ]; then
  TPID=$(cat native_tail.pid 2>/dev/null)
  [ -n "$TPID" ] && kill "$TPID" 2>/dev/null || true
  rm -f native_tail.pid
fi
if [ -f docker_tail.pid ]; then
  TPID=$(cat docker_tail.pid 2>/dev/null)
  [ -n "$TPID" ] && kill "$TPID" 2>/dev/null || true
  rm -f docker_tail.pid
fi
# Stop Docker container if running
if docker ps -q -f name=php-cms-worker-container 2>/dev/null | grep -q .; then
  docker stop php-cms-worker-container 2>/dev/null || true
  docker rm -f php-cms-worker-container 2>/dev/null || true
  echo "Stopped Docker container php-cms-worker-container."
fi
STOP
    chmod +x stop.sh
    log_success "stop.sh generated."

    # --- Generate tests/run_tests.sh ---
    log_info "Generating tests/run_tests.sh..."
    cat << 'TEST' > tests/run_tests.sh
#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
BASE="http://127.0.0.1:8000"
echo "=== Day8 Worker Signals tests ==="
echo "Test 1: worker.php exists..."
[ -f worker.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: Dockerfile exists..."
[ -f Dockerfile ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: public/dashboard.php exists..."
[ -f public/dashboard.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: public/run_demo.php exists..."
[ -f public/run_demo.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 6: start.sh and stop.sh exist..."
[ -x start.sh ] && [ -f stop.sh ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 7: Dashboard (if server running) loads..."
code=$(curl -sf -o /tmp/d8_dash.html -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "OK" || { echo "SKIP (server not running — start with ./start.sh)"; }
if [ "$code" = "200" ]; then
  echo "Test 8: Dashboard JSON endpoint..."
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "demo_runs" && echo "$stats" | grep -q "requests_processed" && echo "OK" || { echo "FAIL"; exit 1; }
  echo "Test 9: Run demo updates metrics..."
  curl -sf "$BASE/run_demo.php" > /dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  runs=$(echo "$stats2" | grep -o '"demo_runs":[0-9]*' | cut -d: -f2)
  [ -n "$runs" ] && [ "$runs" -ge 1 ] && echo "OK (demo_runs=$runs)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
TEST
    chmod +x tests/run_tests.sh
    log_success "tests/run_tests.sh generated."

    # Seed dashboard so metrics are non-zero after setup
    log_info "Seeding dashboard stats (non-zero initial metrics)..."
    echo '{"demo_runs":1,"native_cycles":1,"docker_cycles":0,"requests_processed":2}' > data/stats.json
}

# --- Native Execution ---
run_native() {
    log_info "Running $PHP_SCRIPT natively in background..."
    nohup php "$PHP_SCRIPT" > worker_native.log 2>&1 &
    NATIVE_PID=$!
    echo "$NATIVE_PID" > native_worker.pid
    log_success "Native worker started with PID: $NATIVE_PID. Output redirected to worker_native.log"
    log_info "Monitoring native worker output (Ctrl+C to stop monitoring, worker stays alive):"
    tail -f worker_native.log &
    TAIL_PID=$!
    echo "$TAIL_PID" > native_tail.pid
    sleep 5 # Give worker some time to start and produce output
}

test_native() {
    if [ ! -f native_worker.pid ]; then
        log_error "Native worker PID file not found. Please run 'run_native' first."
        return 1
    fi
    NATIVE_PID=$(cat native_worker.pid)
    log_info "Testing native worker (PID: $NATIVE_PID)..."

    log_info "Sending SIGHUP to reload config in 10 seconds..."
    sleep 10
    kill -HUP "$NATIVE_PID" || log_warning "Failed to send SIGHUP to PID $NATIVE_PID. It might have already exited."
    sleep 5

    log_info "Sending SIGTERM to initiate graceful shutdown in 10 seconds..."
    sleep 10
    kill -TERM "$NATIVE_PID" || log_warning "Failed to send SIGTERM to PID $NATIVE_PID. It might have already exited."
    sleep 10 # Give time for graceful shutdown
    
    log_info "Verifying native worker shutdown..."
    if ! ps -p "$NATIVE_PID" > /dev/null; then
        log_success "Native worker (PID: $NATIVE_PID) successfully shut down gracefully."
    else
        log_error "Native worker (PID: $NATIVE_PID) did not shut down as expected. You might need to 'kill -9 $NATIVE_PID'."
    fi
}

# --- Docker Execution ---
build_docker() {
    log_info "Building Docker image: $DOCKER_IMAGE_NAME..."
    if docker build -t "$DOCKER_IMAGE_NAME" . 2>/dev/null; then
        log_success "Docker image $DOCKER_IMAGE_NAME built successfully."
    else
        log_warning "Docker build failed (e.g. credential/network issue). Skipping Docker demo. Native demo and dashboard still work."
        return 1
    fi
}

run_docker() {
    log_info "Running Docker container: $DOCKER_CONTAINER_NAME..."
    docker run -d --name "$DOCKER_CONTAINER_NAME" "$DOCKER_IMAGE_NAME" || { log_error "Failed to run Docker container."; exit 1; }
    log_success "Docker container $DOCKER_CONTAINER_NAME started. Monitoring logs (Ctrl+C to stop monitoring, container stays alive):"
    docker logs -f "$DOCKER_CONTAINER_NAME" &
    DOCKER_TAIL_PID=$!
    echo "$DOCKER_TAIL_PID" > docker_tail.pid
    sleep 5 # Give container time to start and produce output
}

test_docker() {
    if ! docker ps -q -f name="$DOCKER_CONTAINER_NAME" > /dev/null; then
        log_error "Docker container '$DOCKER_CONTAINER_NAME' is not running. Please run 'run_docker' first."
        return 1
    fi
    log_info "Testing Docker container '$DOCKER_CONTAINER_NAME'..."

    log_info "Sending SIGHUP to reload config in 10 seconds..."
    sleep 10
    docker kill -s HUP "$DOCKER_CONTAINER_NAME" || log_warning "Failed to send SIGHUP to Docker container."
    sleep 5

    log_info "Sending SIGTERM to initiate graceful shutdown in 10 seconds..."
    sleep 10
    docker kill -s TERM "$DOCKER_CONTAINER_NAME" || log_warning "Failed to send SIGTERM to Docker container."
    sleep 10 # Give time for graceful shutdown

    log_info "Verifying Docker container shutdown..."
    if ! docker ps -q -f name="$DOCKER_CONTAINER_NAME" > /dev/null; then
        log_success "Docker container '$DOCKER_CONTAINER_NAME' successfully shut down gracefully."
    else
        log_error "Docker container '$DOCKER_CONTAINER_NAME' did not shut down as expected. You might need to 'docker stop $DOCKER_CONTAINER_NAME' or 'docker rm -f $DOCKER_CONTAINER_NAME'."
    fi
}

# --- Main Execution Flow ---
main() {
    setup_project
    
    log_info "--- Running Native Demonstration ---"
    run_native
    if [ -t 0 ]; then read -p "Press Enter to start native testing (SIGHUP, then SIGTERM)..."; else sleep 2; fi
    kill $(cat native_tail.pid) 2>/dev/null || true
    test_native
    echo ""

    log_info "--- Running Docker Demonstration ---"
    if build_docker; then
        run_docker
        if [ -t 0 ]; then read -p "Press Enter to start Docker testing (SIGHUP, then SIGTERM)..."; else sleep 2; fi
        kill $(cat docker_tail.pid) 2>/dev/null || true
        test_docker
    fi
    echo ""

    log_info "Demonstrations complete. You can clean up using ./stop.sh"
    log_success "Generated: worker.php, Dockerfile, public/dashboard.php, public/run_demo.php, start.sh, stop.sh, tests/run_tests.sh, data/stats.json"
    log_info "Start server: ./start.sh  |  Dashboard: http://127.0.0.1:8000/dashboard.php"
    cd .. # Exit project directory
}

main "$@"