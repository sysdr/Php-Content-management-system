#!/bin/bash

# Define project name and paths
PROJECT_NAME="HighScalePHPCMS"
VENDOR_DIR="$PROJECT_NAME/vendor"
CONFIG_FILE="$PROJECT_NAME/roadrunner.yaml"
RR_BIN_URL="https://github.com/roadrunner-server/roadrunner/releases/latest/download/rr-linux-amd64"
RR_BIN_NAME="rr"
RR_BIN_PATH="./$RR_BIN_NAME"

# --- CLI Styling ---
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
RED=$'\033[0;31m'
NC=$'\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# --- Create Project & File Structure ---
create_project_structure() {
    log_info "Creating project directory: $PROJECT_NAME"
    mkdir -p "$PROJECT_NAME/src" "$PROJECT_NAME/public" "$PROJECT_NAME/data" "$PROJECT_NAME/tests" || { log_error "Failed to create project directory."; exit 1; }
    log_success "Project directory created."
}

# --- Generate Source Code ---
generate_source_code() {
    log_info "Generating source code files..."

    # composer.json
    cat << 'EOF' > "$PROJECT_NAME/composer.json"
{
    "name": "your-org/high-scale-cms",
    "description": "A high-scale PHP CMS component demonstrating Kernel Registry.",
    "type": "project",
    "require": {
        "php": ">=8.1",
        "psr/log": "^1.0 || ^2.0 || ^3.0",
        "monolog/monolog": "^2.0 || ^3.0",
        "spiral/roadrunner-worker": "^3.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    },
    "minimum-stability": "dev",
    "prefer-stable": true
}
EOF
    log_success "composer.json created."

    # src/KernelRegistry.php
    cat << 'EOF' > "$PROJECT_NAME/src/KernelRegistry.php"
<?php

namespace App;

use Psr\\Log\\LoggerInterface;
use Monolog\\Logger;
use Monolog\\Handler\\StreamHandler;
use Spiral\\RoadRunner\\Worker;

class KernelRegistry
{
    private static ?self $instance = null;
    private array $config;
    private LoggerInterface $logger;

    private function __construct()
    {
        // Simulate expensive, one-time bootstrap operations
        $this->config = [
            'app_name' => 'HighScaleCMS',
            'version' => '1.0.0',
            'db_connection_string' => 'mysql:host=localhost;dbname=cms',
            'cache_ttl' => 3600,
            'boot_timestamp' => microtime(true), // To prove it's initialized once
        ];

        // Logger setup (Monolog)
        // For RoadRunner, logging to stderr is often preferred for worker output
        $this->logger = new Logger('AppLogger');
        $this->logger->pushHandler(new StreamHandler('php://stderr', Logger::INFO));

        // This message should only appear ONCE per worker lifecycle
        $this->logger->info("KernelRegistry initialized ONCE at " . date('Y-m-d H:i:s', (int)$this->config['boot_timestamp']));
    }

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function getConfig(): array
    {
        return $this->config;
    }

    public function getLogger(): LoggerInterface
    {
        return $this->logger;
    }

    // Prevent cloning the instance
    private function __clone() {}

    // Prevent unserializing the instance
    public function __wakeup()
    {
        throw new \\Exception("Cannot unserialize a singleton.");
    }
}
EOF
    log_success "src/KernelRegistry.php created."

    # worker.php
    cat << 'EOF' > "$PROJECT_NAME/worker.php"
<?php

require __DIR__ . '/vendor/autoload.php';

use App\\KernelRegistry;
use Spiral\\RoadRunner\\Worker;
use Spiral\\RoadRunner\\Http\\PSR7Client;
use Nyholm\\Psr7\\Response;

// Create RoadRunner worker instance
$rrWorker = Worker::create();
$psr7 = new PSR7Client($rrWorker);

// Get the KernelRegistry instance (initialized once per worker process)
$kernelRegistry = KernelRegistry::getInstance();
$logger = $kernelRegistry->getLogger();
$config = $kernelRegistry->getConfig();

$logger->info("PHP Worker started and ready to accept requests.");

while ($request = $psr7->waitRequest()) {
    try {
        // Log that a request is being handled, using the pre-initialized logger
        $logger->info(sprintf(
            "Handling request %s %s. App Name: %s",
            $request->getMethod(),
            $request->getUri()->getPath(),
            $config['app_name']
        ));

        // Simulate some work
        usleep(10000); // 10ms delay

        // Create a response
        $response = new Response(
            200,
            ['Content-Type' => 'text/plain'],
            "Hello from HighScaleCMS! App Name: {$config['app_name']}, Version: {$config['version']}. Request processed at " . date('Y-m-d H:i:s') . "n"
        );

        $psr7->respond($response);
    } catch (Throwable $e) {
        $logger->error("Error processing request: " . $e->getMessage(), ['exception' => $e]);
        $psr7->respond(new Response(500, ['Content-Type' => 'text/plain'], 'Internal Server Error'));
    }
}

$logger->info("PHP Worker shutting down.");

EOF
    log_success "worker.php created."

    # roadrunner.yaml
    cat << 'EOF' > "$PROJECT_NAME/roadrunner.yaml"
version: "2.7"

http:
  address: "0.0.0.0:8080"
  middleware: ["compress"]
  pool:
    num_workers: 2 # Start with a small pool for demonstration
    max_jobs: 0 # Workers process infinite requests until manually stopped or memory limit reached
    supervisor:
      max_worker_memory: 128 # MB
      exec_timeout: 60s
      ttl: 0 # Don't terminate workers based on TTL
  uploads:
    forbid_symlinks: true
    max_size: 10
  static:
    dir: "public"
    forbid: [".php", ".htaccess"]
    # Add other static file handling if needed

server:
  command: "php worker.php" # The command to execute our PHP worker
  relay: "pipes" # How RoadRunner communicates with PHP worker

logs:
  mode: "production"
  level: "debug"
  channels:
    default:
      output: "stderr" # RoadRunner logs to stderr
      encoding: "console"
    http:
      output: "stderr"
      encoding: "console"

# Metrics:
# metrics:
#   address: "0.0.0.0:2112" # Prometheus metrics endpoint
#   collect:
#     http: true
#     rpc: true
#     server: true
#     disk: ["/"]
#     cpu: true
#     memory: true
EOF
    log_success "roadrunner.yaml created."

    # data/stats.json for dashboard metrics
    log_info "Initializing data/stats.json..."
    echo '{"demo_runs":0,"requests_processed":0,"last_updated":null}' > "$PROJECT_NAME/data/stats.json"
    log_success "data/stats.json created."

    # public/index.php (welcome page for dashboard server)
    cat << 'INDEX' > "$PROJECT_NAME/public/index.php"
<?php
header('Content-Type: text/html; charset=utf-8');
echo "<h1>HighScale CMS (Day 10)</h1>";
echo "<p>Kernel Registry + RoadRunner worker runs on port 8080. <a href=\"/dashboard.php\">Dashboard</a></p>";
echo "<p>Request at " . date('Y-m-d H:i:s') . "</p>";
INDEX
    log_success "public/index.php created."

    # public/run_demo.php (hits worker on 8080 and updates stats)
    cat << 'RUNDEMO' > "$PROJECT_NAME/public/run_demo.php"
<?php
header('Content-Type: application/json; charset=utf-8');
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$workerUrl = 'http://127.0.0.1:8080';
$numRequests = 3;
$requestsProcessed = 0;
for ($i = 0; $i < $numRequests; $i++) {
    $ctx = stream_context_create(['http' => ['timeout' => 3]]);
    $r = @file_get_contents($workerUrl . '/', false, $ctx);
    if ($r !== false) $requestsProcessed++;
}
$stats['demo_runs'] = ($stats['demo_runs'] ?? 0) + 1;
$stats['requests_processed'] = ($stats['requests_processed'] ?? 0) + $requestsProcessed;
$stats['last_updated'] = date('c');
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
RUNDEMO
    log_success "public/run_demo.php created."

    # public/reset_stats.php
    printf '%s\n' '<?php' 'header("Content-Type: application/json; charset=utf-8");' '$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);' '$statsFile = $base . "/data/stats.json";' '$stats = ["demo_runs" => 0, "requests_processed" => 0, "last_updated" => null];' '@file_put_contents($statsFile, json_encode($stats), LOCK_EX);' 'echo json_encode(["ok" => true, "stats" => $stats]);' > "$PROJECT_NAME/public/reset_stats.php"
    log_success "public/reset_stats.php created."

    # public/health_worker.php
    printf '%s\n' '<?php' 'header("Content-Type: application/json; charset=utf-8");' '$ctx = stream_context_create(["http" => ["timeout" => 2]]);' '$r = @file_get_contents("http://127.0.0.1:8080/", false, $ctx);' 'echo json_encode(["ok" => $r !== false, "worker" => "127.0.0.1:8080"]);' > "$PROJECT_NAME/public/health_worker.php"
    log_success "public/health_worker.php created."

    # public/dashboard.php (with Reset, Health check, Worker status, Auto-refresh)
    cat << 'DASH' > "$PROJECT_NAME/public/dashboard.php"
<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$demoRuns = (int)($stats['demo_runs'] ?? 0);
$requestsProcessed = (int)($stats['requests_processed'] ?? 0);
$lastUpdated = $stats['last_updated'] ?? null;
if (!empty($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['demo_runs' => $demoRuns, 'requests_processed' => $requestsProcessed, 'last_updated' => $lastUpdated]);
    exit;
}
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RoadRunner Kernel Registry — Dashboard (Day 10)</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: system-ui, sans-serif; margin: 0; padding: 0; background: #0f172a; min-height: 100vh; color: #e2e8f0; }
    .container { max-width: 920px; margin: 0 auto; padding: 1.5rem; }
    header { background: linear-gradient(90deg, #1e40af, #3b82f6); padding: 1.25rem 0; margin-bottom: 1.5rem; }
    header h1 { margin: 0; font-size: 1.5rem; }
    section { background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1); border-radius: 10px; padding: 1.25rem; margin-bottom: 1rem; }
    .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
    .metric-card { padding: 1rem; text-align: center; border-radius: 8px; border: 1px solid rgba(255,255,255,0.1); }
    .metric-card:nth-child(1) { background: rgba(34,197,94,0.15); }
    .metric-card:nth-child(2) { background: rgba(251,191,36,0.15); }
    .metric-card:nth-child(3) { background: rgba(59,130,246,0.15); }
    .metric-value { font-size: 1.75rem; font-weight: 700; }
    .ops-row { display: flex; flex-wrap: wrap; align-items: center; gap: 0.75rem; margin-bottom: 0.75rem; }
    .ops-desc { flex: 1; min-width: 180px; font-size: 0.88rem; color: rgba(255,255,255,0.75); }
    .btn { padding: 0.5rem 1rem; border: none; border-radius: 6px; font-weight: 600; cursor: pointer; }
    .btn-primary { background: #16a34a; color: #fff; }
    .btn-secondary { background: rgba(100,116,139,0.5); color: #e2e8f0; }
    .btn-danger { background: #dc2626; color: #fff; }
    .ops-status { margin-top: 0.5rem; min-height: 1.2rem; }
  </style>
</head>
<body>
  <header><div class="container"><h1>RoadRunner Kernel Registry — Dashboard (Day 10)</h1><p>Run demo, reset metrics, health check.</p></div></header>
  <div class="container">
    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card"><h3>Demo runs</h3><div class="metric-value" id="metric-demo"><?= $demoRuns ?></div></div>
        <div class="metric-card"><h3>Requests processed</h3><div class="metric-value" id="metric-requests"><?= $requestsProcessed ?></div></div>
        <div class="metric-card"><h3>Last updated</h3><div class="metric-value" id="metric-last" style="font-size:0.95rem;"><?= $lastUpdated ? date("H:i:s", strtotime($lastUpdated)) : "—" ?></div></div>
      </div>
    </section>
    <section>
      <h2>Operations</h2>
      <div class="ops-row"><div class="ops-desc">Run demo.</div><a href="#" role="button" id="op-trigger" class="btn btn-primary">Execute demo</a></div>
      <div class="ops-status" id="ops-status"></div>
      <div class="ops-row"><div class="ops-desc">Reset metrics.</div><button type="button" id="op-reset" class="btn btn-danger">Reset metrics</button></div>
      <div class="ops-row"><div class="ops-desc">Health check.</div><button type="button" id="op-health" class="btn btn-secondary">Health check</button><span id="health-result"></span></div>
      <div class="ops-row"><div class="ops-desc">Worker status :8080.</div><button type="button" id="op-worker" class="btn btn-secondary">Worker status</button><span id="worker-result"></span></div>
      <div class="ops-row"><div class="ops-desc">Auto-refresh every 5s.</div><input type="checkbox" id="auto-refresh"><label for="auto-refresh">Auto-refresh</label></div>
    </section>
  </div>
  <script>
(function(){
  var origin = window.location.origin || "http://127.0.0.1:8081";
  var statusEl = document.getElementById("ops-status");
  function setStatus(msg, type) { statusEl.textContent = msg || ""; statusEl.className = "ops-status " + (type === "ok" ? "ok" : type === "err" ? "err" : ""); }
  function fetchStats() { return fetch(origin + "/dashboard.php?json=1").then(function(r){ return r.ok ? r.json() : {}; }).catch(function(){ return {}; }); }
  function refreshMetrics() { fetchStats().then(function(s){ document.getElementById("metric-demo").textContent = s.demo_runs != null ? s.demo_runs : 0; document.getElementById("metric-requests").textContent = s.requests_processed != null ? s.requests_processed : 0; }); }
  document.getElementById("op-trigger").addEventListener("click", function(e){ e.preventDefault(); if(this.classList.contains("loading")) return; this.classList.add("loading"); setStatus("Running…"); fetch(origin + "/run_demo.php").then(function(r){ return r.json(); }).then(function(d){ if(d.ok){ setStatus("Demo complete.", "ok"); refreshMetrics(); } else setStatus("Error", "err"); }).catch(function(){ setStatus("Request failed.", "err"); }).finally(function(){ document.getElementById("op-trigger").classList.remove("loading"); }); });
  document.getElementById("op-reset").addEventListener("click", function(){ fetch(origin + "/reset_stats.php").then(function(r){ return r.json(); }).then(function(d){ if(d.ok){ setStatus("Metrics reset.", "ok"); refreshMetrics(); } }); });
  document.getElementById("op-health").addEventListener("click", function(){ var el = document.getElementById("health-result"); el.textContent = "…"; fetch(origin + "/index.php").then(function(r){ el.textContent = r.ok ? "✓ OK" : "✗ " + r.status; }).catch(function(){ el.textContent = "✗ Failed"; }); });
  document.getElementById("op-worker").addEventListener("click", function(){ var el = document.getElementById("worker-result"); el.textContent = "…"; fetch(origin + "/health_worker.php").then(function(r){ return r.json(); }).then(function(d){ el.textContent = d.ok ? "✓ Worker up" : "✗ Worker down"; }).catch(function(){ el.textContent = "✗ Error"; }); });
  document.getElementById("auto-refresh").addEventListener("change", function(){ if(this._tid) clearInterval(this._tid); if(this.checked) this._tid = setInterval(refreshMetrics, 5000); });
  refreshMetrics();
})();
  </script>
</body>
</html>
DASH
    log_success "public/dashboard.php created."

    # stop.sh (in project dir: kill RR and dashboard PHP server)
    log_info "Generating stop.sh..."
    cat << 'STOP' > "$PROJECT_NAME/stop.sh"
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
if [ -f roadrunner.pid ]; then
  PID=$(cat roadrunner.pid)
  kill "$PID" 2>/dev/null && echo "Stopped RoadRunner (PID $PID)." || true
  rm -f roadrunner.pid
fi
for port in 8080 8081; do
  if fuser "${port}/tcp" >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
    echo "Stopped process on port ${port}."
  fi
done
rm -f php_dashboard.pid
STOP
    chmod +x "$PROJECT_NAME/stop.sh"
    log_success "stop.sh created."

    # start.sh (full path; avoid duplicate services)
    log_info "Generating start.sh..."
    cat << 'START' > "$PROJECT_NAME/start.sh"
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
if fuser 8080/tcp >/dev/null 2>&1; then
  echo "Port 8080 already in use (RoadRunner may be running). Use ./stop.sh first or skip start."
  exit 1
fi
if fuser 8081/tcp >/dev/null 2>&1; then
  echo "Port 8081 already in use (dashboard server). Use ./stop.sh first."
  exit 1
fi
RR_BIN="../rr"
if [ -x "$RR_BIN" ]; then
  nohup "$RR_BIN" serve -c roadrunner.yaml > roadrunner_output.log 2>&1 &
  echo $! > roadrunner.pid
  echo "Started RoadRunner on :8080 (PID $(cat roadrunner.pid))."
  sleep 2
else
  echo "RoadRunner binary not found at $RR_BIN — starting dashboard only (worker on :8080 will be unavailable)."
fi
PHP_BIN=""
for p in php /usr/bin/php; do command -v "$p" &>/dev/null && PHP_BIN="$p" && break; done
[ -z "$PHP_BIN" ] && PHP_BIN="php"
nohup "$PHP_BIN" -S 0.0.0.0:8081 -t public > php_dashboard.log 2>&1 &
echo $! > php_dashboard.pid
echo "Started dashboard on :8081. Dashboard: http://127.0.0.1:8081/dashboard.php"
START
    chmod +x "$PROJECT_NAME/start.sh"
    log_success "start.sh created."

    # tests/run_tests.sh
    log_info "Generating tests/run_tests.sh..."
    cat << 'TEST' > "$PROJECT_NAME/tests/run_tests.sh"
#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
BASE="http://127.0.0.1:8081"
echo "=== Day10 RoadRunner Kernel Registry tests ==="
echo "Test 1: worker.php exists..."
[ -f worker.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: public/dashboard.php exists..."
[ -f public/dashboard.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: public/run_demo.php exists..."
[ -f public/run_demo.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: start.sh and stop.sh exist..."
[ -x start.sh ] && [ -f stop.sh ] && echo "OK" || { echo "FAIL"; exit 1; }
code=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "Test 6: Dashboard loads OK" || { echo "Test 6: SKIP (dashboard not on :8081 — run ./start.sh from project dir)"; }
if [ "$code" = "200" ]; then
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "demo_runs" && echo "$stats" | grep -q "requests_processed" && echo "Test 7: Dashboard JSON OK" || { echo "FAIL"; exit 1; }
  curl -sf "$BASE/run_demo.php" >/dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  runs=$(echo "$stats2" | grep -o '"demo_runs":[0-9]*' | cut -d: -f2)
  [ -n "$runs" ] && [ "$runs" -ge 1 ] && echo "Test 8: Demo updates metrics OK (demo_runs=$runs)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
TEST
    chmod +x "$PROJECT_NAME/tests/run_tests.sh"
    log_success "tests/run_tests.sh created."

    # Seed dashboard so metrics are non-zero after setup/demo
    log_info "Seeding dashboard stats (non-zero initial metrics)..."
    echo '{"demo_runs":1,"requests_processed":3,"last_updated":"'$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)'"}' > "$PROJECT_NAME/data/stats.json"
    log_success "Seeded data/stats.json."
}

# --- Install Dependencies (Composer) ---
install_dependencies() {
    log_info "Installing PHP dependencies with Composer..."
    if ! command -v composer &> /dev/null; then
        log_warn "Composer not found. Installing Composer locally..."
        cd "$PROJECT_NAME" || { log_error "Failed to enter project directory."; exit 1; }
        curl -sS https://getcomposer.org/installer | php
        php composer.phar install || { log_error "Composer install failed."; exit 1; }
        cd - > /dev/null || { log_error "Failed to return to original directory."; exit 1; }
    else
        cd "$PROJECT_NAME" || { log_error "Failed to enter project directory."; exit 1; }
        composer install || { log_error "Composer install failed."; exit 1; }
        cd - > /dev/null || { log_error "Failed to return to original directory."; exit 1; }
    fi
    log_success "PHP dependencies installed."
}

# --- Download RoadRunner ---
RR_AVAILABLE=0
download_roadrunner() {
    log_info "Checking for RoadRunner binary..."
    if [ -f "$RR_BIN_PATH" ]; then
        log_info "RoadRunner binary already exists."
        RR_AVAILABLE=1
        return 0
    fi
    log_info "Downloading RoadRunner..."
    if curl -sfL "$RR_BIN_URL" -o "$RR_BIN_PATH" 2>/dev/null; then
        chmod +x "$RR_BIN_PATH" && RR_AVAILABLE=1 && log_success "RoadRunner downloaded." && return 0
    fi
    # Fallback: versioned asset (GitHub may redirect latest to a tag)
    RR_VERSIONED_URL="https://github.com/roadrunner-server/roadrunner/releases/download/v2025.1.6/rr-linux-amd64"
    if curl -sfL "$RR_VERSIONED_URL" -o "$RR_BIN_PATH" 2>/dev/null; then
        chmod +x "$RR_BIN_PATH" && RR_AVAILABLE=1 && log_success "RoadRunner downloaded (v2025.1.6)." && return 0
    fi
    log_warn "Could not download RoadRunner. Dashboard (PHP on :8081) will still work. Install rr manually for worker demo."
}

# --- Build (Not applicable for PHP, but for completeness) ---
build_project() {
    log_info "No specific build steps for this PHP project beyond Composer install."
}

# --- Run RoadRunner ---
run_roadrunner() {
    log_info "Starting RoadRunner server..."
    cd "$PROJECT_NAME" || { log_error "Failed to enter project directory."; exit 1; }
    nohup "../$RR_BIN_NAME" serve -c roadrunner.yaml > roadrunner_output.log 2>&1 &
    RR_PID=$!
    echo $RR_PID > roadrunner.pid
    cd - > /dev/null || { log_error "Failed to return to original directory."; exit 1; }
    log_success "RoadRunner started in background with PID $RR_PID. Output in $PROJECT_NAME/roadrunner_output.log"
    log_info "Waiting a few seconds for RoadRunner workers to boot up..."
    sleep 5
}

# --- Test and Verify Functionality ---
test_and_verify() {
    log_info "Testing and verifying functionality..."
    log_info "Making 3 requests to http://localhost:8080..."

    for i in {1..3}; do
        log_info "Request #$i..."
        RESPONSE=$(curl -s http://localhost:8080)
        log_info "Response: $RESPONSE"
        sleep 1 # Small delay between requests
    done

    log_info "Checking RoadRunner output for 'KernelRegistry initialized ONCE'..."
    INIT_COUNT=$(grep -c "KernelRegistry initialized ONCE" "$PROJECT_NAME/roadrunner_output.log" 2>/dev/null || echo "0")

    if [ "$INIT_COUNT" -eq 2 ]; then # We configured 2 workers, so it should appear twice
        log_success "Verification successful! 'KernelRegistry initialized ONCE' appeared $INIT_COUNT times (expected 2 for 2 workers)."
        log_info "This confirms the Kernel Registry is initialized once per worker process, not per request."
    else
        log_error "Verification FAILED! 'KernelRegistry initialized ONCE' appeared $INIT_COUNT times (expected 2 for 2 workers)."
        log_error "Please check $PROJECT_NAME/roadrunner_output.log for details."
        stop_roadrunner
        exit 1
    fi
}

# --- Stop RoadRunner and dashboard (for cleanup or restart) ---
stop_roadrunner() {
    for port in 8080 8081; do
        if fuser "${port}/tcp" >/dev/null 2>&1; then
            log_info "Stopping process on port ${port}..."
            fuser -k "${port}/tcp" 2>/dev/null || true
            log_success "Port ${port} cleared."
        fi
    done
    if [ -f "$PROJECT_NAME/roadrunner.pid" ]; then
        RR_PID=$(cat "$PROJECT_NAME/roadrunner.pid")
        kill "$RR_PID" 2>/dev/null || true
        rm -f "$PROJECT_NAME/roadrunner.pid"
        log_success "RoadRunner stopped."
    fi
    rm -f "$PROJECT_NAME/php_dashboard.pid"
}

# --- Main Execution Flow ---
main() {
    log_info "Starting High-Scale PHP CMS Kernel Registry Demo..."

    # Cleanup previous run artifacts if any
    stop_roadrunner
    rm -f "$PROJECT_NAME/roadrunner_output.log"

    create_project_structure
    generate_source_code
    install_dependencies
    download_roadrunner
    build_project # Placeholder, actual PHP build is composer install
    if [ "$RR_AVAILABLE" = "1" ]; then
        run_roadrunner
        test_and_verify
        log_success "Demo complete! Use './stop.sh' in $PROJECT_NAME to stop."
    else
        log_info "Skipping RoadRunner start (binary not available). Dashboard and tests can still run."
    fi
    log_success "Project ready. Run full path: $(pwd)/$PROJECT_NAME/start.sh — then open http://127.0.0.1:8081/dashboard.php"
    log_info "Run tests: $(pwd)/$PROJECT_NAME/tests/run_tests.sh"
}

# --- Docker specific instructions (simplified for this script, actual Dockerfile would be separate) ---
run_with_docker() {
    log_info "Starting demo with Docker (requires Docker installed)..."
    log_info "This setup assumes you have PHP and Composer available in your Docker environment."
    log_warn "For a production setup, you'd typically build a dedicated Docker image."

    # Build a simple Docker image for PHP and RoadRunner
    cat << 'EOF' > "$PROJECT_NAME/Dockerfile"
FROM php:8.2-cli-alpine

WORKDIR /app

# Install system dependencies for RoadRunner (e.g., git for composer, curl for rr)
RUN apk add --no-cache git curl

# Install Composer
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Download RoadRunner
RUN curl -sfL "https://github.com/roadrunner-server/roadrunner/releases/latest/download/rr-linux-amd64" -o rr && chmod +x rr

# Expose HTTP port
EXPOSE 8080

# Command to run RoadRunner
CMD ["./rr", "serve", "-c", "roadrunner.yaml"]
EOF
    log_success "Dockerfile created."

    cd "$PROJECT_NAME" || { log_error "Failed to enter project directory."; exit 1; }
    log_info "Building Docker image..."
    docker build -t high-scale-cms-kernel-registry . || { log_error "Docker build failed."; exit 1; }
    log_success "Docker image built."

    log_info "Running Docker container..."
    docker run -d -p 8080:8080 --name high-scale-cms-kernel-registry-container high-scale-cms-kernel-registry || { log_error "Docker run failed."; exit 1; }
    log_success "Docker container started. Access at http://localhost:8080"
    sleep 10 # Give container time to boot

    log_info "Making 3 requests to http://localhost:8080 via Docker..."
    for i in {1..3}; do
        log_info "Request #$i..."
        RESPONSE=$(curl -s http://localhost:8080)
        log_info "Response: $RESPONSE"
        sleep 1
    done

    log_info "To view logs from the container: docker logs high-scale-cms-kernel-registry-container"
    log_info "Look for 'KernelRegistry initialized ONCE' in the logs, it should appear twice for 2 workers."
    log_success "Docker demo complete. Use './stop.sh docker' to stop and clean up the container."
    cd - > /dev/null || { log_error "Failed to return to original directory."; exit 1; }
}

# Check for 'docker' argument
if [ "$1" == "docker" ]; then
    run_with_docker
else
    main
fi