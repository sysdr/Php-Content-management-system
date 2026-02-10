#!/bin/bash

# Define project name and directories
PROJECT_NAME="php_cms_leak_detection"
SRC_DIR="$PROJECT_NAME/src"
DOCKER_DIR="$PROJECT_NAME/docker"
PUBLIC_DIR="$PROJECT_NAME/public"
DATA_DIR="$PROJECT_NAME/data"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/$PROJECT_NAME"
START_SCRIPT="$PROJECT_NAME/start.sh"
STOP_SCRIPT="$PROJECT_NAME/stop.sh"
TEST_SCRIPT="$PROJECT_NAME/tests/run_tests.sh"

echo "==================================================="
echo "  Starting PHP CMS Memory Leak Detection Demo    "
echo "==================================================="
echo ""

# --- 1. Create Project Structure ---
echo "1. Creating project directory: $PROJECT_NAME"
mkdir -p "$SRC_DIR" "$DOCKER_DIR" "$PUBLIC_DIR" "$DATA_DIR" "$PROJECT_NAME/tests"
if [ $? -ne 0 ]; then
    echo "Error: Could not create project directories. Exiting."
    exit 1
fi
echo "   Directory structure created."
echo ""

# --- 2. Generate Source Code (Leaky PHP Script) ---
echo "2. Generating PHP source code for memory leak demonstration..."

cat << 'EOF' > "$SRC_DIR/leaky_app.php"
<?php

// Enable explicit garbage collection for demonstration purposes
gc_enable();

class LeakyParent {
    public $children = [];
    public $id;
    public $data; // Add some data to make objects larger

    public function __construct($id) {
        $this->id = $id;
        $this->data = str_repeat('A', 1024); // 1KB of data
    }

    public function addChild(LeakyChild $child) {
        $this->children[] = $child;
    }
}

class LeakyChild {
    public $parent;
    public $id;
    public $data; // Add some data to make objects larger

    public function __construct($id, LeakyParent $parent) {
        $this->id = $id;
        $this->parent = $parent; // THIS IS THE CIRCULAR REFERENCE
        $this->data = str_repeat('B', 512); // 0.5KB of data
    }
}

// A static container to *deliberately* hold references, ensuring a leak for the demo.
// In a real app, this might be a cache, a global registry, or static properties.
class LeakyContainer {
    public static $leakedObjects = [];
}

// --- Main application logic ---
echo "--- Starting Memory Leak Simulation ---\n";
echo "Initial Memory: " . round(memory_get_usage() / (1024 * 1024), 2) . " MB\n";

$iterations = 1000; // Number of objects to create and leak
$gc_interval = 200; // Call gc_collect_cycles() every N iterations

for ($i = 0; $i < $iterations; $i++) {
    $parent = new LeakyParent($i);
    $child = new LeakyChild($i, $parent);
    $parent->addChild($child);

    // Deliberately leak the parent object by storing it in a static array.
    // This prevents PHP's default reference counting from freeing it,
    // and creates a persistent circular reference via $child->parent.
    LeakyContainer::$leakedObjects[] = $parent;

    if (($i + 1) % $gc_interval === 0 || $i === $iterations - 1) {
        echo "Iteration " . ($i + 1) . " (of $iterations) - Current Memory: " . round(memory_get_usage() / (1024 * 1024), 2) . " MB";

        $collected = gc_collect_cycles(); // Manually trigger cyclic GC
        echo " | After gc_collect_cycles() (Collected: $collected cycles): " . round(memory_get_usage() / (1024 * 1024), 2) . " MB\n";

        // Important insight: Even after gc_collect_cycles(), memory still grows significantly
        // because LeakyContainer::$leakedObjects[] holds a direct reference to $parent,
        // preventing the *entire cycle* from being garbage collected.
        // The cycle is A (parent) -> B (child) -> A (parent).
        // LeakyContainer::$leakedObjects[] -> A (parent).
        // Because LeakyContainer::$leakedObjects[] is still reachable, the parent (A) is reachable.
        // Therefore, the child (B) is also reachable. The cycle is NOT "isolated garbage".
        // This demonstrates that gc_collect_cycles() only works on *unreachable* cycles.
        // Our demo intentionally makes the cycle reachable via the static property.
        // A *true* leak that gc_collect_cycles() would fix is if LeakyContainer::$leakedObjects
        // wasn't holding a reference, but the objects A and B still referenced each other
        // and nothing else referenced A or B.
        // For this demo, we aim to show memory *growth* despite GC attempts, indicating a persistent leak.
    }
}

echo "--- Simulation Complete ---\n";
echo "Final Memory: " . round(memory_get_usage() / (1024 * 1024), 2) . " MB\n";
echo "Peak Memory: " . round(memory_get_peak_usage() / (1024 * 1024), 2) . " MB\n";

// Optional: Clear the static array to demonstrate final memory release if needed
// unset(LeakyContainer::$leakedObjects);
// echo "Memory after clearing static reference: " . round(memory_get_usage() / (1024 * 1024), 2) . " MBn";

?>
EOF
echo "   leaky_app.php generated in $SRC_DIR."
echo ""

# --- 3. Build and Run (Directly) ---
echo "3. Running PHP script directly (without Docker):"
echo "   (Observe memory growth even with gc_collect_cycles() calls)"
echo "---------------------------------------------------"
PHP_BIN=""
for p in php /usr/bin/php /usr/local/bin/php; do
  if command -v "$p" &>/dev/null && "$p" -v &>/dev/null 2>&1; then PHP_BIN="$p"; break; fi
done
if [ -n "$PHP_BIN" ]; then
  $PHP_BIN "$SCRIPT_DIR/$SRC_DIR/leaky_app.php"
else
  echo "   (PHP not found — skip direct run. Install PHP or run later: php $SRC_DIR/leaky_app.php)"
fi
echo "---------------------------------------------------"
echo "   Direct execution complete."
echo ""

# --- 3a. Initialize stats for dashboard ---
echo "3a. Initializing data/stats.json for dashboard..."
echo '{"direct_runs":0,"docker_runs":0,"last_peak_memory_mb":0,"last_final_memory_mb":0}' > "$PROJECT_NAME/data/stats.json"
# Seed metrics so dashboard shows non-zero after setup when PHP is available
PHP_BIN=""
for p in php /usr/bin/php /usr/local/bin/php; do
  if command -v "$p" &>/dev/null && "$p" -v &>/dev/null 2>&1; then PHP_BIN="$p"; break; fi
done
if [ -n "$PHP_BIN" ]; then
  run_out=$($PHP_BIN "$SCRIPT_DIR/$SRC_DIR/leaky_app.php" 2>&1) || true
  peak=$(echo "$run_out" | grep "Peak Memory:" | sed -n 's/.*Peak Memory:[^0-9]*\([0-9.]*\).*/\1/p' | tail -1)
  final=$(echo "$run_out" | grep "Final Memory:" | sed -n 's/.*Final Memory:[^0-9]*\([0-9.]*\).*/\1/p' | tail -1)
  if [ -n "$peak" ] && [ -n "$final" ]; then
    echo "{\"direct_runs\":1,\"docker_runs\":0,\"last_peak_memory_mb\":$peak,\"last_final_memory_mb\":$final}" > "$PROJECT_NAME/data/stats.json"
    echo "   data/stats.json seeded with demo run (peak=${peak}MB, final=${final}MB)."
  fi
fi
echo "   data/stats.json created."
echo ""

# --- 3b. Generate public/run_demo.php (updates stats from demo output) ---
echo "3b. Generating public/run_demo.php..."
cat << 'RUNDEMO' > "$PUBLIC_DIR/run_demo.php"
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
RUNDEMO
echo "   run_demo.php generated."
echo ""

# --- 3c. Generate public/dashboard.php ---
echo "3c. Generating public/dashboard.php..."
cat << 'DASH' > "$PUBLIC_DIR/dashboard.php"
<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$directRuns = (int)($stats['direct_runs'] ?? 0);
$dockerRuns = (int)($stats['docker_runs'] ?? 0);
$peakMb = (float)($stats['last_peak_memory_mb'] ?? 0);
$finalMb = (float)($stats['last_final_memory_mb'] ?? 0);
if (!empty($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'direct_runs' => $directRuns,
        'docker_runs' => $dockerRuns,
        'last_peak_memory_mb' => $peakMb,
        'last_final_memory_mb' => $finalMb
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
  <title>PHP CMS Memory Leak Detection — Dashboard (Day 5)</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background: #f5f5f5; color: #222; line-height: 1.5; }
    .container { max-width: 900px; margin: 0 auto; padding: 1.5rem; }
    header { background: #fff; border-bottom: 1px solid #e0e0e0; padding: 1rem 0; margin-bottom: 1.5rem; }
    section { background: #fff; border: 1px solid #e0e0e0; border-radius: 8px; padding: 1.25rem 1.5rem; margin-bottom: 1.25rem; }
    .metrics { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
    .metric-card { background: #fafafa; border: 1px solid #e8e8e8; border-radius: 6px; padding: 1rem; text-align: center; }
    .metric-value { font-size: 2rem; font-weight: 700; color: #1976d2; font-variant-numeric: tabular-nums; }
    .metric-note { font-size: 0.75rem; color: #888; margin-top: 0.35rem; }
    button { padding: 0.6rem 1rem; font-size: 0.9rem; margin: 0.25rem; cursor: pointer; border-radius: 6px; border: 1px solid #1976d2; background: #fff; color: #1976d2; }
    button:hover { background: #1976d2; color: #fff; }
    button.run-demo { background: #2e7d32; color: #fff; border-color: #2e7d32; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .ops-status { margin-top: 0.75rem; min-height: 1.25rem; font-size: 0.9rem; color: #666; }
  </style>
</head>
<body>
  <header><div class="container"><h1>PHP CMS Memory Leak Detection — Dashboard (Day 5)</h1><p>Run demos to update metrics. Values update after each demo run.</p></div></header>
  <div class="container">
    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card"><h3>Direct runs</h3><div class="metric-value" id="metric-direct"><?= $directRuns ?></div><div class="metric-note">PHP script runs</div></div>
        <div class="metric-card"><h3>Docker runs</h3><div class="metric-value" id="metric-docker"><?= $dockerRuns ?></div><div class="metric-note">Container runs</div></div>
        <div class="metric-card"><h3>Last peak memory</h3><div class="metric-value" id="metric-peak"><?= number_format($peakMb, 2) ?></div><div class="metric-note">MB</div></div>
        <div class="metric-card"><h3>Last final memory</h3><div class="metric-value" id="metric-final"><?= number_format($finalMb, 2) ?></div><div class="metric-note">MB</div></div>
      </div>
    </section>
    <section>
      <h2>Operations</h2>
      <button type="button" id="op-direct" class="run-demo">Run direct demo</button>
      <button type="button" id="op-docker" class="run-demo">Run Docker demo</button>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
    </section>
  </div>
  <script>
(function() {
  var origin = window.location.origin || 'http://127.0.0.1:8000';
  var statusEl = document.getElementById('ops-status');
  function setStatus(msg) { statusEl.textContent = msg || ''; }
  function fetchStats() { return fetch(origin + '/dashboard.php?json=1').then(function(r) { return r.ok ? r.json() : {}; }).catch(function() { return {}; }); }
  function refreshMetrics() {
    fetchStats().then(function(s) {
      document.getElementById('metric-direct').textContent = s.direct_runs != null ? s.direct_runs : 0;
      document.getElementById('metric-docker').textContent = s.docker_runs != null ? s.docker_runs : 0;
      document.getElementById('metric-peak').textContent = s.last_peak_memory_mb != null ? Number(s.last_peak_memory_mb).toFixed(2) : '0.00';
      document.getElementById('metric-final').textContent = s.last_final_memory_mb != null ? Number(s.last_final_memory_mb).toFixed(2) : '0.00';
    });
  }
  function runDemo(type) {
    var btn = event.target;
    btn.disabled = true;
    setStatus('Running ' + type + ' demo…');
    fetch(origin + '/run_demo.php?type=' + type).then(function(r) { return r.json(); }).then(function(d) {
      if (d.ok) { setStatus('Done. Metrics updated.'); refreshMetrics(); } else { setStatus(d.error || 'Error'); }
    }).catch(function() { setStatus('Request failed.'); }).finally(function() { btn.disabled = false; });
  }
  document.getElementById('op-direct').onclick = function() { runDemo('direct'); };
  document.getElementById('op-docker').onclick = function() { runDemo('docker'); };
  refreshMetrics();
})();
  </script>
</body>
</html>
DASH
echo "   dashboard.php generated."
echo ""

# --- 3d. Generate start.sh ---
echo "3d. Generating start.sh..."
cat << 'STARTSH' > "$START_SCRIPT"
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
nohup $PHP_BIN -S 127.0.0.1:8000 -t public > /dev/null 2>&1 &
sleep 1
if fuser "8000/tcp" >/dev/null 2>&1; then
  echo "Started PHP server on http://127.0.0.1:8000 — Dashboard: http://127.0.0.1:8000/dashboard.php"
else
  echo "Failed to start PHP server on port 8000. Check that PHP is installed and port is free."
  exit 1
fi
STARTSH
chmod +x "$START_SCRIPT"
echo "   start.sh generated."
echo ""

# --- 3e. Generate stop.sh ---
echo "3e. Generating stop.sh..."
cat << 'STOPSH' > "$STOP_SCRIPT"
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" 2>/dev/null || true
for port in 8000; do
  pid=$(fuser "$port/tcp" 2>/dev/null | tr -d ' ')
  [ -n "$pid" ] && kill $pid 2>/dev/null && echo "Stopped process on port $port (PID $pid)"
done
command -v docker &>/dev/null && docker rm -f php-leak-detector &>/dev/null && echo "Stopped Docker container php-leak-detector" || true
echo "Cleanup done."
STOPSH
chmod +x "$STOP_SCRIPT"
echo "   stop.sh generated."
echo ""

# --- 3f. Generate tests/run_tests.sh ---
echo "3f. Generating tests/run_tests.sh..."
cat << 'TESTSH' > "$TEST_SCRIPT"
#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
BASE="http://127.0.0.1:8000"
echo "=== Running Day5 Memory Leak Detection tests ==="
echo "Test 1: leaky_app.php exists..."
[ -f src/leaky_app.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: Dockerfile exists..."
[ -f docker/Dockerfile ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: Direct PHP run produces memory output..."
if ! command -v php &>/dev/null; then
  echo "SKIP (php not in PATH)"
else
  out=$(php src/leaky_app.php 2>&1)
  echo "$out" | grep -q "Peak Memory:" && echo "$out" | grep -q "Final Memory:" && echo "OK" || { echo "FAIL"; exit 1; }
fi
echo "Test 5: PHP server (if running) dashboard loads..."
code=$(curl -sf -o /tmp/d5_dash.html -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "OK" || { echo "SKIP (server not running — start with ./start.sh)"; }
if [ "$code" = "200" ]; then
  echo "Test 6: Dashboard JSON endpoint..."
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "direct_runs" && echo "$stats" | grep -q "last_peak_memory_mb" && echo "OK" || { echo "FAIL"; exit 1; }
  echo "Test 7: Run direct demo updates metrics..."
  curl -sf "$BASE/run_demo.php?type=direct" > /dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  dr=$(echo "$stats2" | grep -o '"direct_runs":[0-9]*' | cut -d: -f2)
  [ -n "$dr" ] && [ "$dr" -ge 1 ] && echo "OK (direct_runs=$dr)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
TESTSH
chmod +x "$TEST_SCRIPT"
echo "   tests/run_tests.sh generated."
echo ""

# --- 4. Docker Integration (Optional but recommended for consistency) ---
echo "4. Setting up Docker environment..."

cat << 'EOF' > "$DOCKER_DIR/Dockerfile"
FROM php:8.2-cli-alpine

WORKDIR /app

COPY src/leaky_app.php .

CMD ["php", "leaky_app.php"]
EOF
echo "   Dockerfile generated in $DOCKER_DIR."

echo "   Building Docker image..."
USE_DOCKER="no"
if command -v docker &>/dev/null; then
  if docker build -t php-leak-detector "$SCRIPT_DIR/$PROJECT_NAME" -f "$SCRIPT_DIR/$DOCKER_DIR/Dockerfile" 2>/dev/null; then
    USE_DOCKER="yes"
    echo "   Docker image 'php-leak-detector' built successfully."
  else
    echo "   Docker image build failed. Skipping Docker run."
  fi
else
  echo "   (Docker not found — skip image build)"
fi
echo ""

if [ "$USE_DOCKER" == "yes" ]; then
    echo "5. Running PHP script inside Docker container:"
    echo "   (Observe consistent memory growth behavior)"
    echo "---------------------------------------------------"
    docker run --rm php-leak-detector
    echo "---------------------------------------------------"
    echo "   Docker execution complete."
else
    echo "5. Skipping Docker execution due to previous errors."
fi

echo ""
echo "==================================================="
echo "  PHP CMS Memory Leak Detection Demo Finished    "
echo "==================================================="
echo ""
echo "Generated: $SRC_DIR/leaky_app.php, $DOCKER_DIR/Dockerfile,"
echo "  $PUBLIC_DIR/dashboard.php, $PUBLIC_DIR/run_demo.php,"
echo "  $PROJECT_NAME/data/stats.json, $START_SCRIPT, $STOP_SCRIPT, $TEST_SCRIPT"
echo ""
echo "Next steps:"
echo "  Start server:  $SCRIPT_DIR/$START_SCRIPT   (or cd $PROJECT_NAME && ./start.sh)"
echo "  Run tests:     $SCRIPT_DIR/$TEST_SCRIPT    (or cd $PROJECT_NAME && ./tests/run_tests.sh)"
echo "  Clean up:      $SCRIPT_DIR/$STOP_SCRIPT    (or cd $PROJECT_NAME && ./stop.sh)"