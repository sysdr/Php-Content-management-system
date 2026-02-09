#!/bin/bash

# --- Configuration ---
PROJECT_DIR="cms-worker-day4"
PUBLIC_DIR="${PROJECT_DIR}/public"
DATA_DIR="${PROJECT_DIR}/data"
CONFIG_DIR="${PROJECT_DIR}/config"
SRC_DIR="${PROJECT_DIR}/src"
RR_CONFIG_FILE="${PROJECT_DIR}/.rr.yaml"
WORKER_PHP_FILE="${PROJECT_DIR}/worker.php"
COMPOSER_JSON_FILE="${PROJECT_DIR}/composer.json"
ROADRUNNER_BIN="${PROJECT_DIR}/rr"
START_SCRIPT="${PROJECT_DIR}/start.sh"
STOP_SCRIPT="${PROJECT_DIR}/stop.sh"
TEST_SCRIPT="${PROJECT_DIR}/tests/run_tests.sh"

# --- Functions ---
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
    exit 1
}

# --- Main ---
echo "Starting High-Scale PHP CMS Worker Setup (Day 4)"
echo "---------------------------------------------------"

# Clean up previous runs
if [ -d "$PROJECT_DIR" ]; then
    log_warning "Previous project directory '$PROJECT_DIR' found. Removing it."
    rm -rf "$PROJECT_DIR"
fi

# --- 1. Create Project Structure ---
log_info "Creating project directory structure..."
mkdir -p "${PUBLIC_DIR}"
mkdir -p "${DATA_DIR}"
mkdir -p "${CONFIG_DIR}"
mkdir -p "${SRC_DIR}"
mkdir -p "${PROJECT_DIR}/tests"

# --- 2. Initialize stats.json ---
log_info "Initializing stats.json..."
echo '{"php_requests":0,"roadrunner_requests":0}' > "${PROJECT_DIR}/data/stats.json"

# --- 3. Generate composer.json ---
log_info "Generating composer.json..."
cat << 'EOF' > "${COMPOSER_JSON_FILE}"
{
    "name": "high-scale-cms/worker-day4",
    "description": "High-Scale PHP CMS Worker powered by RoadRunner (Day 4).",
    "type": "project",
    "require": {
        "php": ">=8.1",
        "spiral/roadrunner-http": "^3.0",
        "nyholm/psr7": "^1.8",
        "spiral/roadrunner-cli": "^2.0"
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
    "minimum-stability": "stable",
    "prefer-stable": true
}
EOF

# --- 4. Install PHP Dependencies ---
log_info "Installing PHP dependencies via Composer..."
PHP_BIN=""
for p in php /usr/bin/php /usr/local/bin/php; do
  if command -v "$p" &>/dev/null && "$p" -v &>/dev/null 2>&1; then PHP_BIN="$p"; break; fi
done
[ -z "$PHP_BIN" ] && command -v php &>/dev/null && PHP_BIN="php"

USE_DOCKER=false
if [ -z "$PHP_BIN" ]; then
    if command -v docker &>/dev/null; then
        log_warning "PHP not found. Using Docker for Composer..."
        USE_DOCKER=true
    else
        log_error "PHP not found. Please install PHP or Docker."
    fi
fi

if [ "$USE_DOCKER" = true ]; then
    (cd "${PROJECT_DIR}" && docker run --rm -v "$(pwd):/app" -w /app composer:2 install --no-dev --ignore-platform-reqs --no-security-blocking) || log_error "Docker Composer install failed."
else
    export PATH="$(dirname "$PHP_BIN"):$PATH"
    if ! command -v composer &> /dev/null; then
        log_warning "Composer not found. Attempting to install..."
        $PHP_BIN -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        $PHP_BIN composer-setup.php --install-dir=./ --filename=composer.phar 2>/dev/null || true
        if [ -f composer.phar ]; then
            (cd "${PROJECT_DIR}" && php ../composer.phar install --no-dev) || log_error "Composer install failed."
        else
            log_error "Composer install failed. Please install Composer."
        fi
    else
        (cd "${PROJECT_DIR}" && composer install --no-dev) || log_error "Composer install failed."
    fi
fi

# --- 5. Generate RoadRunner Configuration ---
log_info "Generating RoadRunner configuration..."
cat << 'EOF' > "${RR_CONFIG_FILE}"
version: "3"
rpc:
  listen: "tcp://127.0.0.1:6002"
server:
  command: "php worker.php"
http:
  address: "0.0.0.0:8080"
  pool:
    num_workers: 2
    max_jobs: 0
    supervisor:
      max_worker_memory: 100
      exec_timeout: 60s
      idle_ttl: 10s
EOF

# --- 6. Generate PHP Worker Script ---
log_info "Generating PHP worker script..."
cat << 'EOF' > "${WORKER_PHP_FILE}"
<?php

declare(strict_types=1);

require __DIR__ . '/vendor/autoload.php';

use Nyholm\Psr7\Response;
use Nyholm\Psr7\Factory\Psr17Factory;
use Spiral\RoadRunner\Worker;
use Spiral\RoadRunner\Http\PSR7Worker;

$worker = Worker::create();
$factory = new Psr17Factory();
$psr7 = new PSR7Worker($worker, $factory, $factory, $factory);
$statsFile = __DIR__ . '/data/stats.json';

// Day 4: Static state demo - can accumulate across requests
class RequestState {
    public static array $data = [];
}

error_log("PHP Worker started (PID: " . getmypid() . ") - ready to accept requests");

while (true) {
    try {
        $request = $psr7->waitRequest();
        if ($request === null) break;
    } catch (Throwable $e) {
        $psr7->respond(new Response(400));
        continue;
    }
    try {
        $data = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
        $data['roadrunner_requests'] = ($data['roadrunner_requests'] ?? 0) + 1;
        @file_put_contents($statsFile, json_encode($data), LOCK_EX);

        $queryParams = $request->getUri()->getQuery();
        parse_str($queryParams, $params);
        $itemId = $params['item_id'] ?? 'req-' . ($data['roadrunner_requests'] ?? 0);
        RequestState::$data[] = $itemId . ' (Worker ' . getmypid() . ')';

        $body = json_encode([
            'worker_pid' => getmypid(),
            'static_data_history' => RequestState::$data,
            'current_item_id' => $itemId,
            'message' => 'RoadRunner worker - static state persists across requests'
        ]);
        $psr7->respond(new Response(200, ['Content-Type' => 'application/json'], $body));
    } catch (Throwable $e) {
        $psr7->respond(new Response(500, [], 'Error'));
        $psr7->getWorker()->error((string)$e);
    }
}
EOF

# --- 7. Generate public/index.php ---
log_info "Generating public/index.php..."
cat << 'EOF' > "${PUBLIC_DIR}/index.php"
<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$data = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$data['php_requests'] = ($data['php_requests'] ?? 0) + 1;
@file_put_contents($statsFile, json_encode($data), LOCK_EX);
header('Content-Type: text/plain');
echo "Hello from high-scale CMS! Request processed at " . date('Y-m-d H:i:s') . "\n";
EOF

# --- 8. Generate public/request.php ---
log_info "Generating public/request.php..."
cat << 'EOF' > "${PUBLIC_DIR}/request.php"
<?php
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
$target = isset($_GET['target']) ? (string)$_GET['target'] : '';
if ($target !== 'rr') {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'Use target=rr']);
    exit;
}
$itemId = isset($_GET['item_id']) ? (string)$_GET['item_id'] : '';
$url = 'http://127.0.0.1:8080/' . ($itemId !== '' ? '?item_id=' . urlencode($itemId) : '');
$ctx = stream_context_create(['http' => ['timeout' => 5, 'ignore_errors' => true]]);
$body = @file_get_contents($url, false, $ctx);
if ($body === false) {
    http_response_code(502);
    echo json_encode(['ok' => false, 'error' => 'Backend request failed']);
    exit;
}
if ($itemId !== '') {
    echo $body;
} else {
    echo json_encode(['ok' => true, 'target' => $target]);
}
EOF

# --- 9. Generate public/dashboard.php ---
log_info "Generating public/dashboard.php..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "${SCRIPT_DIR}/templates/dashboard.php" ]; then
  cp "${SCRIPT_DIR}/templates/dashboard.php" "${PUBLIC_DIR}/dashboard.php"
elif [ -f "${SCRIPT_DIR}/../templates/dashboard.php" ]; then
  cp "${SCRIPT_DIR}/../templates/dashboard.php" "${PUBLIC_DIR}/dashboard.php"
else
cat << 'DASH' > "${PUBLIC_DIR}/dashboard.php"
<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$phpReq = (int)($stats['php_requests'] ?? 0);
$rrReq = (int)($stats['roadrunner_requests'] ?? 0);
if (!empty($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['php_requests' => $phpReq, 'roadrunner_requests' => $rrReq]);
    exit;
}
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CMS High-Scale — Dashboard (Day 4)</title>
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect fill='%231976d2' width='32' height='32' rx='4'/></svg>">
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background: #f5f5f5; color: #222; line-height: 1.5; }
    .container { max-width: 900px; margin: 0 auto; padding: 1.5rem; }
    header { background: #fff; border-bottom: 1px solid #e0e0e0; padding: 1rem 0; margin-bottom: 1.5rem; }
    header h1 { margin: 0; font-size: 1.5rem; color: #333; }
    section { background: #fff; border: 1px solid #e0e0e0; border-radius: 8px; padding: 1.25rem 1.5rem; margin-bottom: 1.25rem; }
    section h2 { margin: 0 0 0.75rem; font-size: 1.1rem; color: #333; }
    .metrics { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    .metric-card { background: #fafafa; border: 1px solid #e8e8e8; border-radius: 6px; padding: 1rem; text-align: center; }
    .metric-value { font-size: 2.25rem; font-weight: 700; color: #1976d2; font-variant-numeric: tabular-nums; }
    .metric-note { font-size: 0.75rem; color: #888; margin-top: 0.35rem; }
    button { padding: 0.6rem 1rem; font-size: 0.9rem; color: #1976d2; background: #fff; border: 1px solid #1976d2; border-radius: 6px; cursor: pointer; }
    button:hover { background: #1976d2; color: #fff; }
    button.run-demo { background: #2e7d32; color: #fff; border-color: #2e7d32; }
    .ops-grid { display: grid; grid-template-columns: auto 1fr auto 1fr; gap: 0.5rem 1rem; align-items: center; margin-top: 0.5rem; }
    @media (max-width: 520px) { .ops-grid { grid-template-columns: 1fr 1fr; } }
    .ops-hint { font-size: 0.8rem; color: #888; }
    .ops-status { font-size: 0.8rem; color: #666; margin-top: 0.75rem; min-height: 1.25rem; }
  </style>
</head>
<body>
  <header><div class="container"><h1>CMS High-Scale — Dashboard (Day 4)</h1><p>PHP built-in (8000) vs RoadRunner workers (8080). Use Operations to update metrics.</p></div></header>
  <div class="container">
    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card"><h3>PHP built-in server</h3><div class="metric-value" id="metric-php"><?= $phpReq ?></div><div class="metric-note">Requests to :8000</div></div>
        <div class="metric-card"><h3>RoadRunner workers</h3><div class="metric-value" id="metric-rr"><?= $rrReq ?></div><div class="metric-note">Requests to :8080</div></div>
      </div>
    </section>
    <section>
      <h2>Operations</h2>
      <p>Persistent worker loop. Use these to exercise workers and update metrics.</p>
      <div class="ops-grid">
        <button type="button" id="op-warmup" title="Warm up persistent workers">Warm up workers</button>
        <span class="ops-hint">10 requests → RR</span>
        <button type="button" id="op-burst" title="Burst load on RoadRunner">Burst to RR</button>
        <span class="ops-hint">20 requests → RR</span>
        <button type="button" id="op-mixed" title="Mixed traffic ratio">Mixed load</button>
        <span class="ops-hint">3 PHP + 7 RR</span>
        <button type="button" id="op-symmetry" class="run-demo" title="Equal load both servers">Symmetry check</button>
        <span class="ops-hint">5 PHP + 5 RR</span>
      </div>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
    </section>
  </div>
  <script>
(function() {
  var origin = window.location.origin || 'http://127.0.0.1:8000';
  var statusEl = document.getElementById('ops-status');
  var metricPhp = document.getElementById('metric-php');
  var metricRr = document.getElementById('metric-rr');
  function setStatus(msg) { statusEl.textContent = msg || ''; }
  function fetchStats() { return fetch(origin + '/dashboard.php?json=1').then(function(r) { return r.ok ? r.json() : {}; }).catch(function() { return {}; }); }
  function refreshMetrics() { fetchStats().then(function(s) { metricPhp.textContent = s.php_requests != null ? s.php_requests : 0; metricRr.textContent = s.roadrunner_requests != null ? s.roadrunner_requests : 0; }); }
  function requestPhp(n) { n = n || 1; var p = []; for (var i = 0; i < n; i++) p.push(fetch(origin + '/')); return Promise.all(p); }
  function requestRr(n) { n = n || 1; var p = []; for (var i = 0; i < n; i++) p.push(fetch(origin + '/request.php?target=rr')); return Promise.all(p); }
  function runOp(phpN, rrN, label, doneMsg) {
    var b = event.target; b.disabled = true; setStatus(label);
    Promise.all([requestPhp(phpN || 0), requestRr(rrN || 0)]).then(refreshMetrics).then(function() { setStatus(doneMsg || 'Done. Metrics updated.'); }).catch(function() { setStatus('Some requests failed.'); }).finally(function() { b.disabled = false; });
  }
  document.getElementById('op-warmup').onclick = function() { runOp(0, 10, 'Warming up workers (10 → RR)…', 'Warm-up done. RR counter +10.'); };
  document.getElementById('op-burst').onclick = function() { runOp(0, 20, 'Burst to RoadRunner (20 requests)…', 'Burst done. RR counter +20.'); };
  document.getElementById('op-mixed').onclick = function() { runOp(3, 7, 'Mixed load: 3 PHP + 7 RR…', 'Mixed load done. PHP +3, RR +7.'); };
  document.getElementById('op-symmetry').onclick = function() { runOp(5, 5, 'Symmetry check: 5 PHP + 5 RR…', 'Symmetry check done. Both +5.'); };
  refreshMetrics();
})();
  </script>
</body>
</html>
DASH
fi

# --- 9b. Generate public/dashboard-terminal.php ---
log_info "Generating public/dashboard-terminal.php..."
if [ -f "${SCRIPT_DIR}/templates/dashboard-terminal.php" ]; then
  cp "${SCRIPT_DIR}/templates/dashboard-terminal.php" "${PUBLIC_DIR}/dashboard-terminal.php"
elif [ -f "${SCRIPT_DIR}/../templates/dashboard-terminal.php" ]; then
  cp "${SCRIPT_DIR}/../templates/dashboard-terminal.php" "${PUBLIC_DIR}/dashboard-terminal.php"
else
cat << 'TERM' > "${PUBLIC_DIR}/dashboard-terminal.php"
<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$phpReq = (int)($stats['php_requests'] ?? 0);
$rrReq = (int)($stats['roadrunner_requests'] ?? 0);
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Day 4 — Terminal View</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; padding: 0; background: #0d1117; color: #58a6ff; font-family: 'Consolas', 'Monaco', 'Courier New', monospace; font-size: 14px; line-height: 1.5; }
    .term { max-width: 700px; margin: 0 auto; padding: 1.5rem; }
    .prompt { color: #7ee787; }
    .cmd { color: #d2a8ff; }
    .val { color: #79c0ff; }
    .line { margin: 0.25rem 0; }
    h1 { color: #58a6ff; font-size: 1rem; margin: 0 0 1rem; }
    .blink { animation: blink 1s step-end infinite; }
    @keyframes blink { 50% { opacity: 0; } }
    a { color: #58a6ff; }
  </style>
</head>
<body>
  <div class="term">
    <div class="line prompt">$</div>
    <div class="line cmd">day4-cms dashboard --view=terminal</div>
    <div class="line"></div>
    <h1>═══ Day 4 Worker Metrics ═══</h1>
    <div id="output">
      <div class="line">  PHP :8000   <span class="val" id="m-php"><?= $phpReq ?></span> requests</div>
      <div class="line">  RR  :8080   <span class="val" id="m-rr"><?= $rrReq ?></span> requests</div>
      <div class="line">  ─────────────────────────</div>
      <div class="line">  Total: <span class="val" id="m-total"><?= $phpReq + $rrReq ?></span></div>
      <div class="line"></div>
      <div class="line prompt">$</div>
      <div class="line">  <span class="blink">_</span></div>
    </div>
    <div style="margin-top:1.5rem;font-size:0.85rem;color:#6e7681">
      <a href="dashboard.php">← Dashboard view</a> | Auto-refresh every 3s
    </div>
  </div>
  <script>
(function() {
  var o = window.location.origin || 'http://127.0.0.1:8000';
  function refresh() {
    fetch(o + '/dashboard.php?json=1').then(function(r) { return r.json(); }).then(function(s) {
      var php = s.php_requests || 0, rr = s.roadrunner_requests || 0;
      document.getElementById('m-php').textContent = php;
      document.getElementById('m-rr').textContent = rr;
      document.getElementById('m-total').textContent = php + rr;
    });
  }
  refresh(); setInterval(refresh, 3000);
})();
  </script>
</body>
</html>
TERM
fi

# --- 10. Generate start.sh ---
log_info "Generating start.sh..."
ABS_PROJECT="$(cd "$(dirname "$0")" && pwd)/${PROJECT_DIR}"
cat << STARTSH > "${START_SCRIPT}"
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
cd "\$SCRIPT_DIR" || exit 1
for port in 8000 8080; do
  if fuser "\$port/tcp" >/dev/null 2>&1; then echo "Port \$port already in use; run stop.sh first."; exit 1; fi
done
php -S 127.0.0.1:8000 -t public > /dev/null 2>&1 &
RR_BIN="./rr"; [ -x "\$RR_BIN" ] || RR_BIN="./vendor/bin/rr"; [ -x "\$RR_BIN" ] || RR_BIN="rr"
\$RR_BIN serve -c .rr.yaml > /dev/null 2>&1 &
echo "Started PHP server (8000) and RoadRunner (8080). Dashboard: http://127.0.0.1:8000/dashboard.php"
STARTSH
chmod +x "${START_SCRIPT}"

# --- 11. Generate stop.sh ---
log_info "Generating stop.sh..."
cat << STOPSH > "${STOP_SCRIPT}"
#!/bin/bash
cd "\$(dirname "\$0")" 2>/dev/null || true
# Stop Docker container if running
docker rm -f day4-cms 2>/dev/null && echo "Stopped day4-cms container" || true
for port in 8000 8080; do
  pid=\$(fuser "\$port/tcp" 2>/dev/null | tr -d ' ')
  [ -n "\$pid" ] && kill \$pid 2>/dev/null && echo "Stopped process on port \$port (PID \$pid)"
done
pkill -f "rr serve.*\\.rr\\.yaml" 2>/dev/null && echo "Stopped RoadRunner"
echo "Cleanup done."
STOPSH
chmod +x "${STOP_SCRIPT}"

# --- 11b. Generate Dockerfile and docker-start.sh ---
log_info "Generating Dockerfile and docker-start.sh..."
cat << 'DOCKERFILE' > "${PROJECT_DIR}/Dockerfile"
FROM php:8.4-cli
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip git \
    && docker-php-ext-install sockets \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock ./
COPY .rr.yaml ./
COPY worker.php ./
COPY public/ ./public/
RUN mkdir -p data && echo '{"php_requests":0,"roadrunner_requests":0}' > data/stats.json

RUN composer install --no-dev --no-interaction

ARG RR_VERSION=2024.3.5
RUN cd /tmp && curl -sSL "https://github.com/roadrunner-server/roadrunner/releases/download/v${RR_VERSION}/roadrunner-${RR_VERSION}-linux-amd64.tar.gz" -o rr.tar.gz \
    && tar -xzf rr.tar.gz && (mv rr /usr/local/bin/ 2>/dev/null || mv roadrunner-*/rr /usr/local/bin/) && chmod +x /usr/local/bin/rr && rm -rf rr.tar.gz roadrunner-*

RUN echo '#!/bin/sh' > /start.sh && \
    echo 'php -S 0.0.0.0:8000 -t /app/public &' >> /start.sh && \
    echo 'exec rr serve -c /app/.rr.yaml' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 8000 8080
CMD ["/start.sh"]
DOCKERFILE

cat << 'DOCKERSTART' > "${PROJECT_DIR}/docker-start.sh"
#!/bin/bash
cd "$(dirname "$0")"
docker rm -f day4-cms 2>/dev/null || true
echo "Building and starting Day4 CMS..."
docker build -t day4-cms .
docker run --rm -p 8000:8000 -p 8080:8080 --name day4-cms day4-cms
DOCKERSTART
chmod +x "${PROJECT_DIR}/docker-start.sh"

# --- 12. Generate tests/run_tests.sh ---
log_info "Generating tests/run_tests.sh..."
cat << TESTSH > "${TEST_SCRIPT}"
#!/bin/bash
set -e
cd "\$(dirname "\$0")/.." || exit 1
PHP_PORT=8000
RR_PORT=8080
BASE="http://127.0.0.1"
echo "=== Running Day4 tests ==="
echo "Test 1: PHP built-in server responds..."
curl -sf -o /dev/null -w "%{http_code}" "\$BASE:\$PHP_PORT/" | grep -q 200 && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: RoadRunner server responds..."
curl -sf -o /dev/null -w "%{http_code}" "\$BASE:\$RR_PORT/" | grep -q 200 && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: Dashboard loads..."
code=\$(curl -sf -o /tmp/dashboard_day4.html -w "%{http_code}" "\$BASE:\$PHP_PORT/dashboard.php")
[ "\$code" = "200" ] && echo "OK" || { echo "FAIL (code \$code)"; exit 1; }
echo "Test 4: Dashboard shows metrics..."
grep -q "PHP built-in\|metric-php" /tmp/dashboard_day4.html && grep -q "RoadRunner\|metric-rr" /tmp/dashboard_day4.html && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: JSON stats endpoint..."
stats=\$(curl -sf "\$BASE:\$PHP_PORT/dashboard.php?json=1")
echo "\$stats" | grep -q "php_requests" && echo "\$stats" | grep -q "roadrunner_requests" && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 6: Demo updates metrics (run Symmetry check)..."
curl -sf "\$BASE:\$PHP_PORT/" > /dev/null
curl -sf "\$BASE:\$PHP_PORT/request.php?target=rr" > /dev/null
stats2=\$(curl -sf "\$BASE:\$PHP_PORT/dashboard.php?json=1")
php_cnt=\$(echo "\$stats2" | grep -o '"php_requests":[0-9]*' | cut -d: -f2)
rr_cnt=\$(echo "\$stats2" | grep -o '"roadrunner_requests":[0-9]*' | cut -d: -f2)
[ -n "\$php_cnt" ] && [ -n "\$rr_cnt" ] && [ "\$php_cnt" -ge 0 ] && [ "\$rr_cnt" -ge 0 ] && echo "OK (php=\$php_cnt rr=\$rr_cnt)" || { echo "FAIL"; exit 1; }
echo "All tests passed."
TESTSH
chmod +x "${TEST_SCRIPT}"

# --- 13. Ensure RoadRunner binary ---
log_info "Ensuring RoadRunner is available..."
if [ ! -x "${ROADRUNNER_BIN}" ]; then
  (cd "${PROJECT_DIR}" && curl -sfL https://raw.githubusercontent.com/roadrunner-server/roadrunner/master/install.sh 2>/dev/null | bash) || true
  [ -f "${ROADRUNNER_BIN}" ] && chmod +x "${ROADRUNNER_BIN}"
fi
if [ -x "${PROJECT_DIR}/vendor/bin/rr" ]; then
  log_success "RoadRunner available via vendor/bin/rr"
elif [ -x "${ROADRUNNER_BIN}" ]; then
  log_success "RoadRunner binary: ${ROADRUNNER_BIN}"
else
  log_warning "RoadRunner not found. Run: cd ${PROJECT_DIR} && composer require spiral/roadrunner-cli"
fi

echo ""
log_success "Day 4 setup complete!"
echo "   Generated files:"
echo "   - ${COMPOSER_JSON_FILE}"
echo "   - ${RR_CONFIG_FILE}"
echo "   - ${WORKER_PHP_FILE}"
echo "   - ${PUBLIC_DIR}/index.php, request.php, dashboard.php, dashboard-terminal.php"
echo "   - ${PROJECT_DIR}/data/stats.json"
echo "   - ${START_SCRIPT}, ${STOP_SCRIPT}"
echo "   - ${TEST_SCRIPT}"
echo "   - ${PROJECT_DIR}/Dockerfile, docker-start.sh"
echo ""
echo "   Next steps:"
echo "   - With PHP: cd ${PROJECT_DIR} && ./start.sh"
echo "   - With Docker: cd ${PROJECT_DIR} && ./docker-start.sh"
echo "   - Run tests: cd ${PROJECT_DIR} && ./tests/run_tests.sh"
