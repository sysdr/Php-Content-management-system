<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$phpReq = (int)($stats['php_requests'] ?? 0);
$rrReq = (int)($stats['roadrunner_requests'] ?? 0);
$view = isset($_GET['view']) ? (string)$_GET['view'] : 'default';

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
  <title>Worker Metrics & Static State</title>
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect fill='%23636f86' width='32' height='32' rx='4'/></svg>">
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: 'JetBrains Mono', 'Fira Code', 'SF Mono', monospace;
      margin: 0; padding: 0;
      background: #1a1d23;
      color: #e6e9ef;
      line-height: 1.6;
      min-height: 100vh;
    }
    .container { max-width: 1100px; margin: 0 auto; padding: 1.5rem; }
    header {
      background: linear-gradient(135deg, #2d3139 0%, #252830 100%);
      border: 1px solid #3d4149;
      border-radius: 12px;
      padding: 1.25rem 1.5rem;
      margin-bottom: 1.25rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.75rem;
    }
    header h1 { margin: 0; font-size: 1.35rem; color: #7eb8da; font-weight: 600; }
    header p { margin: 0.25rem 0 0; font-size: 0.85rem; color: #9ca3af; }
    .view-switch { display: flex; gap: 0.5rem; }
    .view-switch a {
      padding: 0.4rem 0.8rem;
      font-size: 0.8rem;
      text-decoration: none;
      border-radius: 6px;
      background: #2d3139;
      color: #9ca3af;
      border: 1px solid #3d4149;
    }
    .view-switch a:hover { background: #3d4149; color: #7eb8da; }
    .view-switch a.active { background: #4a90d9; color: #fff; border-color: #4a90d9; }
    section {
      background: #252830;
      border: 1px solid #3d4149;
      border-radius: 10px;
      padding: 1.25rem 1.5rem;
      margin-bottom: 1.25rem;
    }
    section h2 { margin: 0 0 0.75rem; font-size: 1rem; color: #7eb8da; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
    .metrics { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; }
    @media (max-width: 700px) { .metrics { grid-template-columns: 1fr; } }
    .metric-card {
      background: #1a1d23;
      border: 1px solid #3d4149;
      border-radius: 8px;
      padding: 1rem;
      text-align: center;
      transition: border-color 0.2s;
    }
    .metric-card:hover { border-color: #5a6b7d; }
    .metric-value { font-size: 2rem; font-weight: 700; color: #7eb8da; font-variant-numeric: tabular-nums; }
    .metric-card.ratio .metric-value { color: #a8d08d; }
    .metric-card.timing .metric-value { font-size: 1.5rem; color: #e5c07b; }
    .metric-note { font-size: 0.75rem; color: #6b7280; margin-top: 0.35rem; }
    .bar-chart { display: flex; align-items: flex-end; gap: 0.5rem; height: 60px; margin-top: 0.75rem; }
    .bar { flex: 1; background: #3d4149; border-radius: 4px 4px 0 0; min-height: 4px; transition: height 0.3s; }
    .bar.php { background: linear-gradient(to top, #4a90d9, #7eb8da); }
    .bar.rr { background: linear-gradient(to top, #2e7d32, #a8d08d); }
    .bar-label { font-size: 0.7rem; color: #6b7280; text-align: center; margin-top: 0.25rem; }
    button {
      padding: 0.5rem 1rem;
      font-size: 0.85rem;
      font-family: inherit;
      color: #7eb8da;
      background: #1a1d23;
      border: 1px solid #3d4149;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.2s;
    }
    button:hover { background: #2d3139; border-color: #5a6b7d; color: #e6e9ef; }
    button.run-demo { background: #2e7d32; color: #fff; border-color: #2e7d32; }
    button.run-demo:hover { background: #3d8f40; }
    button.danger { color: #e06c75; }
    button.danger:hover { border-color: #e06c75; }
    .ops-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 0.5rem; margin-top: 0.5rem; }
    .ops-hint { font-size: 0.75rem; color: #6b7280; }
    .ops-status { font-size: 0.8rem; color: #9ca3af; margin-top: 0.75rem; min-height: 1.25rem; }
    .static-state {
      background: #1a1d23;
      border: 1px solid #3d4149;
      border-radius: 8px;
      padding: 1rem;
      font-size: 0.85rem;
      font-family: 'JetBrains Mono', monospace;
      white-space: pre-wrap;
      word-break: break-all;
      max-height: 200px;
      overflow-y: auto;
      margin-top: 0.5rem;
    }
    .static-state .key { color: #e5c07b; }
    .static-state .str { color: #a8d08d; }
    .static-state .num { color: #d19a66; }
    .probe-row { display: flex; gap: 0.5rem; align-items: center; margin-top: 0.5rem; flex-wrap: wrap; }
    .probe-row input { padding: 0.5rem; border-radius: 6px; border: 1px solid #3d4149; background: #1a1d23; color: #e6e9ef; font-family: inherit; width: 180px; }
    .timing-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-top: 0.5rem; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div>
        <h1>Worker Metrics & Static State</h1>
        <p>PHP :8000 vs RoadRunner :8080 • Static state persists across requests</p>
      </div>
      <div class="view-switch">
        <a href="?view=default" class="<?= $view === 'default' ? 'active' : '' ?>">Dashboard</a>
        <a href="dashboard-terminal.php">Terminal view</a>
      </div>
    </header>

    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card">
          <h3 style="margin:0;font-size:0.9rem;color:#9ca3af">PHP built-in</h3>
          <div class="metric-value" id="metric-php"><?= $phpReq ?></div>
          <div class="metric-note">Requests to :8000</div>
        </div>
        <div class="metric-card">
          <h3 style="margin:0;font-size:0.9rem;color:#9ca3af">RoadRunner</h3>
          <div class="metric-value" id="metric-rr"><?= $rrReq ?></div>
          <div class="metric-note">Requests to :8080</div>
        </div>
        <div class="metric-card ratio">
          <h3 style="margin:0;font-size:0.9rem;color:#9ca3af">PHP : RR ratio</h3>
          <div class="metric-value" id="metric-ratio"><?= $phpReq + $rrReq > 0 ? round($phpReq / max(1, $phpReq + $rrReq) * 100) . '% : ' . round($rrReq / max(1, $phpReq + $rrReq) * 100) . '%' : '—' ?></div>
          <div class="metric-note">Traffic split</div>
        </div>
      </div>
      <div class="bar-chart">
        <div style="flex:1;display:flex;flex-direction:column;align-items:center">
          <div class="bar php" id="bar-php" style="height:<?= $phpReq + $rrReq > 0 ? max(10, min(60, 60 * $phpReq / max($phpReq, $rrReq, 1))) : 4 ?>px"></div>
          <span class="bar-label">PHP</span>
        </div>
        <div style="flex:1;display:flex;flex-direction:column;align-items:center">
          <div class="bar rr" id="bar-rr" style="height:<?= $phpReq + $rrReq > 0 ? max(10, min(60, 60 * $rrReq / max($phpReq, $rrReq, 1))) : 4 ?>px"></div>
          <span class="bar-label">RR</span>
        </div>
      </div>
    </section>

    <section>
      <h2>Response timing (avg ms)</h2>
      <div class="timing-grid">
        <div class="metric-card timing">
          <div class="metric-value" id="timing-php">—</div>
          <div class="metric-note">PHP built-in avg</div>
        </div>
        <div class="metric-card timing">
          <div class="metric-value" id="timing-rr">—</div>
          <div class="metric-note">RoadRunner avg</div>
        </div>
      </div>
    </section>

    <section>
      <h2>Load operations</h2>
      <p style="margin:0 0 0.5rem;color:#9ca3af;font-size:0.9rem">Generate traffic to update metrics.</p>
      <div class="ops-grid">
        <button type="button" id="op-warmup">Warm up</button>
        <button type="button" id="op-burst">Burst</button>
        <button type="button" id="op-mixed">Mixed</button>
        <button type="button" id="op-symmetry" class="run-demo">Symmetry</button>
        <button type="button" id="op-stress" class="danger">Stress</button>
      </div>
      <div style="display:flex;gap:1rem;flex-wrap:wrap;margin-top:0.5rem;font-size:0.75rem;color:#6b7280">
        <span>Warm: 10 RR</span><span>Burst: 20 RR</span><span>Mixed: 3+7</span><span>Sym: 5+5</span><span>Stress: 50+50</span>
      </div>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
    </section>

    <section>
      <h2>Static state explorer</h2>
      <p style="margin:0 0 0.5rem;color:#9ca3af;font-size:0.9rem">Send item_id to RR worker — static state accumulates across requests.</p>
      <div class="probe-row">
        <input type="text" id="probe-item" placeholder="item_id (e.g. apple)" value="demo-1">
        <button type="button" id="op-probe">Inspect worker state</button>
      </div>
      <div class="static-state" id="static-output">Click "Inspect worker state" to see persistent static_data_history.</div>
    </section>
  </div>

  <script>
(function() {
  var origin = window.location.origin || 'http://127.0.0.1:8000';
  var statusEl = document.getElementById('ops-status');
  var metricPhp = document.getElementById('metric-php');
  var metricRr = document.getElementById('metric-rr');
  var metricRatio = document.getElementById('metric-ratio');
  var barPhp = document.getElementById('bar-php');
  var barRr = document.getElementById('bar-rr');
  var timingPhp = document.getElementById('timing-php');
  var timingRr = document.getElementById('timing-rr');
  var staticOutput = document.getElementById('static-output');

  var timePhp = []; var timeRr = [];

  function setStatus(msg) { statusEl.textContent = msg || ''; }
  function fetchStats() { return fetch(origin + '/dashboard.php?json=1').then(function(r) { return r.ok ? r.json() : {}; }).catch(function() { return {}; }); }

  function refreshMetrics() {
    fetchStats().then(function(s) {
      var php = s.php_requests != null ? s.php_requests : 0;
      var rr = s.roadrunner_requests != null ? s.roadrunner_requests : 0;
      metricPhp.textContent = php;
      metricRr.textContent = rr;
      var total = php + rr || 1;
      metricRatio.textContent = Math.round(php/total*100) + '% : ' + Math.round(rr/total*100) + '%';
      var max = Math.max(php, rr, 1);
      barPhp.style.height = Math.max(10, 60 * php / max) + 'px';
      barRr.style.height = Math.max(10, 60 * rr / max) + 'px';
    });
  }

  function requestPhp(n) {
    n = n || 1;
    var p = [];
    for (var i = 0; i < n; i++) {
      var start = performance.now();
      p.push(fetch(origin + '/').then(function(r) {
        timePhp.push(performance.now() - start);
        if (timePhp.length > 20) timePhp.shift();
        return r;
      }));
    }
    return Promise.all(p);
  }

  function requestRr(n, itemId) {
    n = n || 1;
    var url = origin + '/request.php?target=rr' + (itemId ? '&item_id=' + encodeURIComponent(itemId) : '');
    var p = [];
    for (var i = 0; i < n; i++) {
      var start = performance.now();
      p.push(fetch(url).then(function(r) {
        timeRr.push(performance.now() - start);
        if (timeRr.length > 20) timeRr.shift();
        return r;
      }));
    }
    return Promise.all(p);
  }

  function updateTiming() {
    timingPhp.textContent = timePhp.length ? Math.round(timePhp.reduce(function(a,b){return a+b;},0) / timePhp.length) + ' ms' : '—';
    timingRr.textContent = timeRr.length ? Math.round(timeRr.reduce(function(a,b){return a+b;},0) / timeRr.length) + ' ms' : '—';
  }

  function runOp(phpN, rrN, label, doneMsg) {
    var b = event.target; b.disabled = true; setStatus(label);
    Promise.all([requestPhp(phpN || 0), requestRr(rrN || 0)]).then(refreshMetrics).then(updateTiming).then(function() { setStatus(doneMsg || 'Done.'); }).catch(function() { setStatus('Some requests failed.'); }).finally(function() { b.disabled = false; });
  }

  document.getElementById('op-warmup').onclick = function() { runOp(0, 10, 'Warming up…', 'Warm-up done.'); };
  document.getElementById('op-burst').onclick = function() { runOp(0, 20, 'Burst to RR…', 'Burst done.'); };
  document.getElementById('op-mixed').onclick = function() { runOp(3, 7, 'Mixed load…', 'Mixed done.'); };
  document.getElementById('op-symmetry').onclick = function() { runOp(5, 5, 'Symmetry…', 'Symmetry done.'); };
  document.getElementById('op-stress').onclick = function() { runOp(50, 50, 'Stress test…', 'Stress done.'); };

  document.getElementById('op-probe').onclick = function() {
    var itemId = document.getElementById('probe-item').value || 'probe';
    staticOutput.textContent = 'Loading…';
    var url = origin + '/request.php?target=rr&item_id=' + encodeURIComponent(itemId);
    fetch(url).then(function(r) { return r.json(); }).then(function(data) {
      staticOutput.textContent = JSON.stringify(data, null, 2);
    }).catch(function(e) {
      staticOutput.textContent = 'Error: ' + e.message;
    });
  };

  refreshMetrics();
  setInterval(refreshMetrics, 5000);
})();
  </script>
</body>
</html>
