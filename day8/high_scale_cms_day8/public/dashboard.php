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
