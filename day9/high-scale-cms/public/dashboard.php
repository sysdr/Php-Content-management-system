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
  <title>FrankenPHP — Dashboard (Day 9)</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: 'DM Sans', 'Segoe UI', system-ui, sans-serif; margin: 0; padding: 0; background: linear-gradient(165deg, #1c1917 0%, #292524 35%, #1f1d1b 70%, #0c0a09 100%); min-height: 100vh; color: #fafaf9; line-height: 1.5; }
    .container { max-width: 960px; margin: 0 auto; padding: 1.5rem; }
    header { background: linear-gradient(105deg, #b45309 0%, #d97706 25%, #ea580c 60%, #c2410c 100%); color: #fff; padding: 1.5rem 0; margin-bottom: 1.5rem; box-shadow: 0 6px 24px rgba(180, 83, 9, 0.35); border-radius: 0 0 16px 16px; }
    header h1 { margin: 0 0 0.25rem; font-size: 1.75rem; font-weight: 700; letter-spacing: -0.02em; }
    header p { margin: 0; opacity: 0.95; font-size: 0.95rem; }
    .nav-links { margin-top: 0.75rem; }
    .nav-links a { color: rgba(255,255,255,0.9); text-decoration: none; font-size: 0.85rem; margin-right: 1rem; padding: 0.35rem 0.6rem; border-radius: 6px; background: rgba(0,0,0,0.2); transition: background 0.15s; }
    .nav-links a:hover { background: rgba(0,0,0,0.35); }
    section { background: rgba(255, 255, 255, 0.04); border: 1px solid rgba(251, 146, 60, 0.18); border-radius: 14px; padding: 1.4rem 1.75rem; margin-bottom: 1.25rem; }
    section h2 { margin: 0 0 1rem; font-size: 0.95rem; font-weight: 600; color: #fdba74; text-transform: uppercase; letter-spacing: 0.08em; }
    .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
    @media (max-width: 640px) { .metrics { grid-template-columns: 1fr; } }
    .metric-card { border-radius: 12px; padding: 1.2rem; text-align: center; border: 1px solid rgba(251, 146, 60, 0.2); }
    .metric-card:nth-child(1) { background: linear-gradient(145deg, rgba(217, 119, 6, 0.2), rgba(180, 83, 9, 0.06)); border-color: rgba(217, 119, 6, 0.4); }
    .metric-card:nth-child(2) { background: linear-gradient(145deg, rgba(234, 88, 12, 0.2), rgba(194, 65, 12, 0.06)); border-color: rgba(234, 88, 12, 0.4); }
    .metric-card:nth-child(3) { background: linear-gradient(145deg, rgba(251, 146, 60, 0.15), rgba(249, 115, 22, 0.05)); border-color: rgba(251, 146, 60, 0.3); }
    .metric-card h3 { margin: 0 0 0.45rem; font-size: 0.75rem; font-weight: 600; color: rgba(255, 255, 255, 0.75); text-transform: uppercase; letter-spacing: 0.05em; }
    .metric-value { font-size: 2rem; font-weight: 700; font-variant-numeric: tabular-nums; }
    .metric-card:nth-child(1) .metric-value { color: #fbbf24; }
    .metric-card:nth-child(2) .metric-value { color: #fb923c; }
    .metric-card:nth-child(3) .metric-value { color: #fdba74; }
    .metric-note { font-size: 0.7rem; color: rgba(255, 255, 255, 0.45); margin-top: 0.3rem; }
    .ops-row { display: flex; flex-wrap: wrap; align-items: center; gap: 0.75rem; margin-bottom: 0.75rem; }
    .ops-row:last-of-type { margin-bottom: 0; }
    .ops-desc { flex: 1; min-width: 180px; font-size: 0.88rem; color: rgba(255, 255, 255, 0.7); }
    .btn { display: inline-flex; align-items: center; gap: 0.45rem; padding: 0.55rem 1rem; border: none; border-radius: 8px; font-size: 0.88rem; font-weight: 600; cursor: pointer; text-decoration: none; transition: transform 0.1s, box-shadow 0.1s; }
    .btn-primary { background: linear-gradient(135deg, #d97706, #b45309); color: #fff; box-shadow: 0 2px 8px rgba(217, 119, 6, 0.35); }
    .btn-primary:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(217, 119, 6, 0.45); }
    .btn-secondary { background: rgba(120, 113, 108, 0.4); color: #fafaf9; border: 1px solid rgba(251, 146, 60, 0.25); }
    .btn-secondary:hover { background: rgba(120, 113, 108, 0.55); }
    .btn-danger { background: linear-gradient(135deg, #b91c1c, #991b1b); color: #fff; }
    .btn-danger:hover { transform: translateY(-1px); }
    .btn.loading { opacity: 0.7; cursor: wait; }
    .ops-status { margin-top: 0.6rem; min-height: 1.2rem; font-size: 0.88rem; color: rgba(255, 255, 255, 0.65); }
    .ops-status.ok { color: #86efac; }
    .ops-status.err { color: #fca5a5; }
    .last-updated { font-size: 0.8rem; color: rgba(255, 255, 255, 0.5); margin-top: 1rem; }
    .toggle-wrap { display: flex; align-items: center; gap: 0.5rem; }
    .toggle-wrap label { font-size: 0.85rem; color: rgba(255, 255, 255, 0.7); cursor: pointer; user-select: none; }
    .toggle-wrap input[type="checkbox"] { width: 1.1rem; height: 1.1rem; accent-color: #d97706; cursor: pointer; }
    #health-result { font-size: 0.85rem; margin-left: 0.5rem; }
  </style>
</head>
<body>
  <header>
    <div class="container">
      <h1>FrankenPHP — Dashboard (Day 9)</h1>
      <p>High-Scale CMS. Run demos, reset metrics, and monitor health.</p>
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
        <div class="metric-card"><h3>Requests processed</h3><div class="metric-value" id="metric-requests"><?= $requestsProcessed ?></div><div class="metric-note">Hits to index</div></div>
        <div class="metric-card"><h3>Last updated</h3><div class="metric-value" id="metric-last" style="font-size:1rem;">—</div><div class="metric-note" id="metric-last-note">After demo or reset</div></div>
      </div>
      <div class="last-updated" id="last-updated"></div>
    </section>
    <section>
      <h2>Operations</h2>
      <div class="ops-row">
        <div class="ops-desc">Run demo: send requests to index and update metrics.</div>
        <a href="#" role="button" id="op-trigger" class="btn btn-primary" aria-label="Execute demo"><span>▶</span><span>Execute demo</span></a>
      </div>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
      <div class="ops-row">
        <div class="ops-desc">Reset demo runs and requests to zero.</div>
        <button type="button" id="op-reset" class="btn btn-danger">Reset metrics</button>
      </div>
      <div class="ops-row">
        <div class="ops-desc">Ping the index page to verify the app is responding.</div>
        <button type="button" id="op-health" class="btn btn-secondary">Health check</button>
        <span id="health-result"></span>
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
(function() {
  var origin = window.location.origin || 'http://127.0.0.1:8000';
  var statusEl = document.getElementById('ops-status');
  var triggerEl = document.getElementById('op-trigger');
  var resetEl = document.getElementById('op-reset');
  var healthEl = document.getElementById('op-health');
  var healthResult = document.getElementById('health-result');
  var autoRefreshEl = document.getElementById('auto-refresh');
  var refreshTimer = null;

  function setStatus(msg, type) { statusEl.textContent = msg || ''; statusEl.className = 'ops-status' + (type === 'ok' ? ' ok' : type === 'err' ? ' err' : ''); }
  function fetchStats() { return fetch(origin + '/dashboard.php?json=1').then(function(r) { return r.ok ? r.json() : {}; }).catch(function() { return {}; }); }

  function formatLastUpdated(iso) {
    if (!iso) return '—';
    var d = new Date(iso);
    var now = new Date();
    var sec = Math.floor((now - d) / 1000);
    if (sec < 60) return sec + 's ago';
    if (sec < 3600) return Math.floor(sec / 60) + 'm ago';
    return d.toLocaleString();
  }

  function refreshMetrics() {
    fetchStats().then(function(s) {
      document.getElementById('metric-demo').textContent = s.demo_runs != null ? s.demo_runs : 0;
      document.getElementById('metric-requests').textContent = s.requests_processed != null ? s.requests_processed : 0;
      var last = s.last_updated || null;
      document.getElementById('metric-last').textContent = last ? formatLastUpdated(last) : '—';
      document.getElementById('last-updated').textContent = last ? 'Last updated: ' + new Date(last).toLocaleString() : '';
    });
  }

  triggerEl.addEventListener('click', function(e) {
    e.preventDefault();
    if (triggerEl.classList.contains('loading')) return;
    triggerEl.classList.add('loading');
    setStatus('Running…');
    fetch(origin + '/run_demo.php').then(function(r) { return r.json(); }).then(function(d) {
      if (d.ok) { setStatus('Demo complete. Metrics updated.', 'ok'); refreshMetrics(); }
      else { setStatus(d.error || 'Error', 'err'); }
    }).catch(function() { setStatus('Request failed.', 'err'); }).finally(function() { triggerEl.classList.remove('loading'); });
  });

  resetEl.addEventListener('click', function() {
    if (resetEl.classList.contains('loading')) return;
    resetEl.classList.add('loading');
    fetch(origin + '/reset_stats.php').then(function(r) { return r.json(); }).then(function(d) {
      if (d.ok) { setStatus('Metrics reset.', 'ok'); refreshMetrics(); }
      else { setStatus('Reset failed.', 'err'); }
    }).catch(function() { setStatus('Reset failed.', 'err'); }).finally(function() { resetEl.classList.remove('loading'); });
  });

  healthEl.addEventListener('click', function() {
    healthResult.textContent = '…';
    fetch(origin + '/').then(function(r) {
      if (r.ok) healthResult.textContent = '✓ OK';
      else healthResult.textContent = '✗ ' + r.status;
    }).catch(function() { healthResult.textContent = '✗ Failed'; });
  });

  autoRefreshEl.addEventListener('change', function() {
    if (refreshTimer) clearInterval(refreshTimer);
    if (autoRefreshEl.checked) refreshTimer = setInterval(refreshMetrics, 5000);
  });

  refreshMetrics();
})();
  </script>
</body>
</html>
