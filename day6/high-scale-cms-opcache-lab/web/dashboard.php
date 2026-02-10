<?php
$statsFile = __DIR__ . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$webRequests = (int)($stats['web_requests'] ?? 0);
$cliRuns = (int)($stats['cli_runs'] ?? 0);
$lastWebMs = (float)($stats['last_web_time_ms'] ?? 0);
$lastCliSec = (float)($stats['last_cli_time_s'] ?? 0);
$opcacheCached = (int)($stats['opcache_cached_scripts'] ?? 0);
$jitEnabled = !empty($stats['jit_enabled']);
if (!empty($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'web_requests' => $webRequests,
        'cli_runs' => $cliRuns,
        'last_web_time_ms' => $lastWebMs,
        'last_cli_time_s' => $lastCliSec,
        'opcache_cached_scripts' => $opcacheCached,
        'jit_enabled' => $jitEnabled
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
  <title>OPcache & JIT Lab — Dashboard</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%); min-height: 100vh; color: #e8e8e8; line-height: 1.5; }
    .container { max-width: 900px; margin: 0 auto; padding: 1.5rem; }
    header { background: linear-gradient(90deg, #e94560 0%, #c73e54 100%); color: #fff; padding: 1.25rem 0; margin-bottom: 1.5rem; box-shadow: 0 4px 12px rgba(233, 69, 96, 0.35); }
    header h1 { margin: 0 0 0.25rem; font-size: 1.6rem; font-weight: 700; }
    header p { margin: 0; opacity: 0.95; font-size: 0.95rem; }
    section { background: rgba(255, 255, 255, 0.06); border: 1px solid rgba(255, 255, 255, 0.12); border-radius: 12px; padding: 1.25rem 1.5rem; margin-bottom: 1.25rem; }
    section h2 { margin: 0 0 1rem; font-size: 1.1rem; color: #e94560; font-weight: 600; }
    .metrics { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
    .metric-card { border-radius: 10px; padding: 1.1rem; text-align: center; border: 1px solid rgba(255, 255, 255, 0.1); }
    .metric-card:nth-child(1) { background: linear-gradient(145deg, rgba(78, 205, 196, 0.25), rgba(78, 205, 196, 0.08)); border-color: rgba(78, 205, 196, 0.4); }
    .metric-card:nth-child(2) { background: linear-gradient(145deg, rgba(247, 157, 101, 0.25), rgba(247, 157, 101, 0.08)); border-color: rgba(247, 157, 101, 0.4); }
    .metric-card:nth-child(3) { background: linear-gradient(145deg, rgba(155, 207, 246, 0.25), rgba(155, 207, 246, 0.08)); border-color: rgba(155, 207, 246, 0.4); }
    .metric-card:nth-child(4) { background: linear-gradient(145deg, rgba(206, 147, 216, 0.25), rgba(206, 147, 216, 0.08)); border-color: rgba(206, 147, 216, 0.4); }
    .metric-card:nth-child(5) { background: linear-gradient(145deg, rgba(129, 199, 132, 0.25), rgba(129, 199, 132, 0.08)); border-color: rgba(129, 199, 132, 0.4); }
    .metric-card:nth-child(6) { background: linear-gradient(145deg, rgba(255, 183, 77, 0.25), rgba(255, 183, 77, 0.08)); border-color: rgba(255, 183, 77, 0.4); }
    .metric-card h3 { margin: 0 0 0.5rem; font-size: 0.85rem; font-weight: 600; color: rgba(255, 255, 255, 0.85); text-transform: uppercase; letter-spacing: 0.04em; }
    .metric-value { font-size: 2rem; font-weight: 700; font-variant-numeric: tabular-nums; }
    .metric-card:nth-child(1) .metric-value { color: #4ecdc4; }
    .metric-card:nth-child(2) .metric-value { color: #f79d65; }
    .metric-card:nth-child(3) .metric-value { color: #9bcff6; }
    .metric-card:nth-child(4) .metric-value { color: #ce93d8; }
    .metric-card:nth-child(5) .metric-value { color: #81c784; }
    .metric-card:nth-child(6) .metric-value { color: #ffb74d; }
    .metric-note { font-size: 0.75rem; color: rgba(255, 255, 255, 0.55); margin-top: 0.35rem; }
    button { padding: 0.65rem 1.2rem; font-size: 0.9rem; margin: 0.25rem; cursor: pointer; border-radius: 8px; border: none; font-weight: 600; transition: transform 0.15s, box-shadow 0.15s; }
    button:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,0,0,0.25); }
    button:active { transform: translateY(0); }
    #op-web { background: linear-gradient(135deg, #4ecdc4, #44a08d); color: #fff; }
    #op-web:hover { background: linear-gradient(135deg, #5dd9d0, #4ecdc4); }
    #op-cli { background: linear-gradient(135deg, #f79d65, #e07b45); color: #fff; }
    #op-cli:hover { background: linear-gradient(135deg, #ffad75, #f79d65); }
    button:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }
    .ops-status { margin-top: 0.75rem; min-height: 1.25rem; font-size: 0.9rem; color: rgba(255, 255, 255, 0.7); }
  </style>
</head>
<body>
  <header><div class="container"><h1>OPcache & JIT Lab — Dashboard</h1><p>Run demos to update metrics. Values update after each demo run.</p></div></header>
  <div class="container">
    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card"><h3>Web requests</h3><div class="metric-value" id="metric-web"><?= $webRequests ?></div><div class="metric-note">Hits to index.php</div></div>
        <div class="metric-card"><h3>CLI runs</h3><div class="metric-value" id="metric-cli"><?= $cliRuns ?></div><div class="metric-note">CLI task runs</div></div>
        <div class="metric-card"><h3>Last web time</h3><div class="metric-value" id="metric-web-ms"><?= number_format($lastWebMs, 2) ?></div><div class="metric-note">ms</div></div>
        <div class="metric-card"><h3>Last CLI time</h3><div class="metric-value" id="metric-cli-s"><?= number_format($lastCliSec, 3) ?></div><div class="metric-note">s</div></div>
        <div class="metric-card"><h3>OPcache cached</h3><div class="metric-value" id="metric-opcache"><?= $opcacheCached ?></div><div class="metric-note">scripts</div></div>
        <div class="metric-card"><h3>JIT enabled</h3><div class="metric-value" id="metric-jit"><?= $jitEnabled ? 'Yes' : 'No' ?></div><div class="metric-note">opcache.jit</div></div>
      </div>
    </section>
    <section>
      <h2>Operations</h2>
      <button type="button" id="op-web" class="run-demo">Run web demo</button>
      <button type="button" id="op-cli" class="run-demo">Run CLI demo</button>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
    </section>
  </div>
  <script>
(function() {
  var origin = window.location.origin || '';
  var statusEl = document.getElementById('ops-status');
  function setStatus(msg) { statusEl.textContent = msg || ''; }
  function fetchStats() { return fetch(origin + '/dashboard.php?json=1').then(function(r) { return r.ok ? r.json() : {}; }).catch(function() { return {}; }); }
  function refreshMetrics() {
    fetchStats().then(function(s) {
      document.getElementById('metric-web').textContent = s.web_requests != null ? s.web_requests : 0;
      document.getElementById('metric-cli').textContent = s.cli_runs != null ? s.cli_runs : 0;
      document.getElementById('metric-web-ms').textContent = s.last_web_time_ms != null ? Number(s.last_web_time_ms).toFixed(2) : '0.00';
      document.getElementById('metric-cli-s').textContent = s.last_cli_time_s != null ? Number(s.last_cli_time_s).toFixed(3) : '0.000';
      document.getElementById('metric-opcache').textContent = s.opcache_cached_scripts != null ? s.opcache_cached_scripts : 0;
      document.getElementById('metric-jit').textContent = s.jit_enabled ? 'Yes' : 'No';
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
  document.getElementById('op-web').onclick = function() { runDemo('web'); };
  document.getElementById('op-cli').onclick = function() { runDemo('cli'); };
  refreshMetrics();
})();
  </script>
</body>
</html>
