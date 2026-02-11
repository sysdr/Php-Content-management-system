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
  <link rel="icon" href="/favicon.php" type="image/gif">
  <title>RoadRunner Kernel Registry — Dashboard (Day 10)</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: system-ui, sans-serif; margin: 0; padding: 0; background: #0f172a; min-height: 100vh; color: #e2e8f0; }
    .container { max-width: 920px; margin: 0 auto; padding: 1.5rem; }
    header { background: linear-gradient(90deg, #1e40af, #3b82f6); padding: 1.25rem 0; margin-bottom: 1.5rem; }
    header h1 { margin: 0; font-size: 1.5rem; }
    header p { margin: 0.25rem 0 0; opacity: 0.95; font-size: 0.9rem; }
    .nav-links { margin-top: 0.75rem; }
    .nav-links a { color: rgba(255,255,255,0.9); text-decoration: none; font-size: 0.85rem; margin-right: 0.75rem; padding: 0.35rem 0.6rem; border-radius: 6px; background: rgba(0,0,0,0.2); }
    .nav-links a:hover { background: rgba(0,0,0,0.35); }
    section { background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1); border-radius: 10px; padding: 1.25rem; margin-bottom: 1rem; }
    section h2 { margin: 0 0 1rem; font-size: 0.9rem; font-weight: 600; color: #93c5fd; text-transform: uppercase; letter-spacing: 0.05em; }
    .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
    @media (max-width: 640px) { .metrics { grid-template-columns: 1fr; } }
    .metric-card { padding: 1rem; text-align: center; border-radius: 8px; border: 1px solid rgba(255,255,255,0.1); }
    .metric-card:nth-child(1) { background: rgba(34,197,94,0.15); }
    .metric-card:nth-child(2) { background: rgba(251,191,36,0.15); }
    .metric-card:nth-child(3) { background: rgba(59,130,246,0.15); }
    .metric-value { font-size: 1.75rem; font-weight: 700; font-variant-numeric: tabular-nums; }
    .metric-note { font-size: 0.7rem; color: rgba(255,255,255,0.5); margin-top: 0.25rem; }
    .ops-row { display: flex; flex-wrap: wrap; align-items: center; gap: 0.75rem; margin-bottom: 0.75rem; }
    .ops-row:last-of-type { margin-bottom: 0; }
    .ops-desc { flex: 1; min-width: 180px; font-size: 0.88rem; color: rgba(255,255,255,0.75); }
    .btn { display: inline-flex; align-items: center; gap: 0.4rem; padding: 0.5rem 1rem; border: none; border-radius: 6px; font-size: 0.88rem; font-weight: 600; cursor: pointer; text-decoration: none; transition: opacity 0.15s; }
    .btn:hover { opacity: 0.9; }
    .btn-primary { background: #16a34a; color: #fff; }
    .btn-secondary { background: rgba(100,116,139,0.5); color: #e2e8f0; border: 1px solid rgba(255,255,255,0.15); }
    .btn-danger { background: #dc2626; color: #fff; }
    .btn.loading { opacity: 0.7; cursor: wait; }
    .ops-status { margin-top: 0.5rem; min-height: 1.2rem; font-size: 0.88rem; color: rgba(255,255,255,0.7); }
    .ops-status.ok { color: #4ade80; }
    .ops-status.err { color: #f87171; }
    .last-updated { font-size: 0.8rem; color: rgba(255,255,255,0.5); margin-top: 0.75rem; }
    .toggle-wrap { display: flex; align-items: center; gap: 0.5rem; }
    .toggle-wrap label { font-size: 0.85rem; color: rgba(255,255,255,0.75); cursor: pointer; user-select: none; }
    .toggle-wrap input[type="checkbox"] { width: 1.1rem; height: 1.1rem; accent-color: #3b82f6; cursor: pointer; }
    .inline-result { font-size: 0.85rem; margin-left: 0.5rem; }
  </style>
</head>
<body>
  <header>
    <div class="container">
      <h1>RoadRunner Kernel Registry — Dashboard (Day 10)</h1>
      <p>Run demo, reset metrics, and check health of worker and dashboard.</p>
      <div class="nav-links">
        <a href="/dashboard.php">Dashboard</a>
      </div>
    </div>
  </header>
  <div class="container">
    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card"><h3>Demo runs</h3><div class="metric-value" id="metric-demo"><?= $demoRuns ?></div><div class="metric-note">Total demo executions</div></div>
        <div class="metric-card"><h3>Requests processed</h3><div class="metric-value" id="metric-requests"><?= $requestsProcessed ?></div><div class="metric-note">Hits to worker :8080</div></div>
        <div class="metric-card"><h3>Last updated</h3><div class="metric-value" id="metric-last" style="font-size:0.95rem;"><?= $lastUpdated ? date('H:i:s', strtotime($lastUpdated)) : '—' ?></div><div class="metric-note" id="metric-last-note">After demo or reset</div></div>
      </div>
      <div class="last-updated" id="last-updated"></div>
    </section>
    <section>
      <h2>Operations</h2>
      <div class="ops-row">
        <div class="ops-desc">Run demo: send requests to worker on :8080 and update metrics.</div>
        <a href="#" role="button" id="op-trigger" class="btn btn-primary">▶ Execute demo</a>
      </div>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
      <div class="ops-row">
        <div class="ops-desc">Reset demo runs and requests to zero.</div>
        <button type="button" id="op-reset" class="btn btn-danger">Reset metrics</button>
      </div>
      <div class="ops-row">
        <div class="ops-desc">Ping this dashboard server to verify it is responding.</div>
        <button type="button" id="op-health" class="btn btn-secondary">Health check (dashboard)</button>
        <span class="inline-result" id="health-result"></span>
      </div>
      <div class="ops-row">
        <div class="ops-desc">Check if RoadRunner worker on :8080 is reachable.</div>
        <button type="button" id="op-worker" class="btn btn-secondary">Worker status (:8080)</button>
        <span class="inline-result" id="worker-result"></span>
      </div>
      <div class="ops-row">
        <div class="ops-desc">Reload metrics from server once.</div>
        <button type="button" id="op-refresh" class="btn btn-secondary">Refresh metrics</button>
      </div>
      <div class="ops-row">
        <div class="ops-desc">Refresh metrics automatically every 5 seconds.</div>
        <div class="toggle-wrap">
          <input type="checkbox" id="auto-refresh" aria-label="Auto-refresh metrics">
          <label for="auto-refresh">Auto-refresh</label>
        </div>
      </div>
    </section>
  </div>
  <script>
(function(){
  var origin = window.location.origin || 'http://127.0.0.1:8081';
  var statusEl = document.getElementById('ops-status');
  var triggerEl = document.getElementById('op-trigger');
  var resetEl = document.getElementById('op-reset');
  var healthEl = document.getElementById('op-health');
  var healthResult = document.getElementById('health-result');
  var workerEl = document.getElementById('op-worker');
  var workerResult = document.getElementById('worker-result');
  var refreshEl = document.getElementById('op-refresh');
  var autoRefreshEl = document.getElementById('auto-refresh');
  var refreshTimer = null;

  function setStatus(msg, type) {
    statusEl.textContent = msg || '';
    statusEl.className = 'ops-status' + (type === 'ok' ? ' ok' : type === 'err' ? ' err' : '');
  }
  function fetchStats() {
    return fetch(origin + '/dashboard.php?json=1').then(function(r){ return r.ok ? r.json() : {}; }).catch(function(){ return {}; });
  }
  function formatLast(iso) {
    if (!iso) return '—';
    var d = new Date(iso);
    var sec = Math.floor((new Date() - d) / 1000);
    if (sec < 60) return sec + 's ago';
    if (sec < 3600) return Math.floor(sec / 60) + 'm ago';
    return d.toLocaleTimeString();
  }
  function refreshMetrics() {
    fetchStats().then(function(s){
      document.getElementById('metric-demo').textContent = s.demo_runs != null ? s.demo_runs : 0;
      document.getElementById('metric-requests').textContent = s.requests_processed != null ? s.requests_processed : 0;
      var last = s.last_updated || null;
      document.getElementById('metric-last').textContent = last ? formatLast(last) : '—';
      document.getElementById('last-updated').textContent = last ? 'Last updated: ' + new Date(last).toLocaleString() : '';
    });
  }

  triggerEl.addEventListener('click', function(e){
    e.preventDefault();
    if (triggerEl.classList.contains('loading')) return;
    triggerEl.classList.add('loading');
    setStatus('Running…');
    fetch(origin + '/run_demo.php').then(function(r){ return r.json(); }).then(function(d){
      if (d.ok) { setStatus('Demo complete. Metrics updated.', 'ok'); refreshMetrics(); }
      else setStatus(d.error || 'Error', 'err');
    }).catch(function(){ setStatus('Request failed.', 'err'); }).finally(function(){ triggerEl.classList.remove('loading'); });
  });

  resetEl.addEventListener('click', function(){
    if (resetEl.classList.contains('loading')) return;
    resetEl.classList.add('loading');
    fetch(origin + '/reset_stats.php').then(function(r){ return r.json(); }).then(function(d){
      if (d.ok) { setStatus('Metrics reset.', 'ok'); refreshMetrics(); }
      else setStatus('Reset failed.', 'err');
    }).catch(function(){ setStatus('Reset failed.', 'err'); }).finally(function(){ resetEl.classList.remove('loading'); });
  });

  healthEl.addEventListener('click', function(){
    healthResult.textContent = '…';
    fetch(origin + '/index.php').then(function(r){
      healthResult.textContent = r.ok ? '✓ OK' : '✗ ' + r.status;
    }).catch(function(){ healthResult.textContent = '✗ Failed'; });
  });

  workerEl.addEventListener('click', function(){
    workerResult.textContent = '…';
    fetch(origin + '/health_worker.php').then(function(r){ return r.json(); }).then(function(d){
      workerResult.textContent = d.ok ? '✓ Worker up' : '✗ Worker down';
    }).catch(function(){ workerResult.textContent = '✗ Error'; });
  });

  refreshEl.addEventListener('click', function(){
    refreshMetrics();
    setStatus('Metrics refreshed.', 'ok');
    setTimeout(function(){ setStatus(''); }, 2000);
  });

  autoRefreshEl.addEventListener('change', function(){
    if (refreshTimer) clearInterval(refreshTimer);
    if (autoRefreshEl.checked) refreshTimer = setInterval(refreshMetrics, 5000);
  });

  refreshMetrics();
})();
  </script>
</body>
</html>
