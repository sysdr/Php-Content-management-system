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
  <title>CMS High-Scale — Dashboard</title>
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
  <header><div class="container"><h1>CMS High-Scale — Dashboard</h1><p>PHP built-in (8000) vs RoadRunner workers (8080). Use Operations to update metrics.</p></div></header>
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
