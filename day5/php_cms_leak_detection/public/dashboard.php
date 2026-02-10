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
