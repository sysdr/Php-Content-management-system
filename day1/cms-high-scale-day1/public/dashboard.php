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
  <title>CMS High-Scale Day1 — Dashboard</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      margin: 0;
      padding: 0;
      background: #f5f5f5;
      color: #222;
      line-height: 1.5;
    }
    .container { max-width: 900px; margin: 0 auto; padding: 1.5rem; }
    header {
      background: #fff;
      border-bottom: 1px solid #e0e0e0;
      padding: 1rem 0;
      margin-bottom: 1.5rem;
    }
    header h1 { margin: 0; font-size: 1.5rem; color: #333; font-weight: 600; }
    header p { margin: 0.25rem 0 0; font-size: 0.875rem; color: #666; }

    section {
      background: #fff;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      padding: 1.25rem 1.5rem;
      margin-bottom: 1.25rem;
      box-shadow: 0 1px 2px rgba(0,0,0,0.04);
    }
    section h2 {
      margin: 0 0 0.75rem;
      font-size: 1.1rem;
      font-weight: 600;
      color: #333;
      border-bottom: 1px solid #eee;
      padding-bottom: 0.5rem;
    }
    .project-info { font-size: 0.9rem; color: #444; }
    .project-info ul { margin: 0.5rem 0 0 1.25rem; padding: 0; }
    .project-info li { margin: 0.25rem 0; }

    .metrics {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
    }
    @media (max-width: 600px) { .metrics { grid-template-columns: 1fr; } }
    .metric-card {
      background: #fafafa;
      border: 1px solid #e8e8e8;
      border-radius: 6px;
      padding: 1rem;
      text-align: center;
    }
    .metric-card h3 { margin: 0 0 0.5rem; font-size: 0.95rem; font-weight: 600; color: #555; }
    .metric-value {
      font-size: 2.25rem;
      font-weight: 700;
      color: #1976d2;
      font-variant-numeric: tabular-nums;
    }
    .metric-note { font-size: 0.75rem; color: #888; margin-top: 0.35rem; }

    .ops h2 { margin-bottom: 0.75rem; }
    .ops-desc { font-size: 0.875rem; color: #555; margin-bottom: 1rem; }
    .ops-buttons {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      align-items: center;
    }
    button {
      padding: 0.6rem 1rem;
      font-size: 0.9rem;
      font-weight: 500;
      color: #1976d2;
      background: #fff;
      border: 1px solid #1976d2;
      border-radius: 6px;
      cursor: pointer;
      transition: background 0.15s, color 0.15s;
    }
    button:hover { background: #1976d2; color: #fff; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    button.run-demo { background: #2e7d32; color: #fff; border-color: #2e7d32; }
    button.run-demo:hover { background: #1b5e20; border-color: #1b5e20; }
    .ops-status { font-size: 0.8rem; color: #666; margin-top: 0.75rem; min-height: 1.25rem; }

    footer { font-size: 0.8rem; color: #888; margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <header>
    <div class="container">
      <h1>CMS High-Scale Day1 — Dashboard</h1>
      <p>PHP built-in server vs RoadRunner • Metrics update in real time when you use the operations below.</p>
    </div>
  </header>

  <div class="container">
    <section class="project-info">
      <h2>About this project</h2>
      <p>This demo compares two ways to run PHP for a high-scale CMS:</p>
      <ul>
        <li><strong>PHP built-in server</strong> (port 8000) — Each request boots PHP from scratch (FPM-like).</li>
        <li><strong>RoadRunner</strong> (port 8080) — Persistent PHP workers handle many requests without re-booting, reducing “bootload tax” and improving throughput.</li>
      </ul>
      <p>Use the <strong>Operations</strong> section below to send requests to either server. The metrics above update in real time.</p>
    </section>

    <section>
      <h2>Live metrics</h2>
      <div class="metrics">
        <div class="metric-card">
          <h3>PHP built-in server</h3>
          <div class="metric-value" id="metric-php"><?= $phpReq ?></div>
          <div class="metric-note">Requests to :8000</div>
        </div>
        <div class="metric-card">
          <h3>RoadRunner workers</h3>
          <div class="metric-value" id="metric-rr"><?= $rrReq ?></div>
          <div class="metric-note">Requests to :8080</div>
        </div>
      </div>
    </section>

    <section class="ops">
      <h2>Operations</h2>
      <p class="ops-desc">Send requests to each server to see the counters increase. These actions update the metrics in real time.</p>
      <div class="ops-buttons">
        <button type="button" id="op-php" title="Send one request to PHP built-in server">1 request → PHP (:8000)</button>
        <button type="button" id="op-rr" title="Send one request to RoadRunner">1 request → RoadRunner (:8080)</button>
        <button type="button" id="op-demo" class="run-demo" title="Send 5 requests to each server">Run demo (5 each)</button>
      </div>
      <div class="ops-status" id="ops-status" aria-live="polite"></div>
    </section>

    <footer>
      <p>Setup: <code>./setup.sh</code> from day1 • Start servers: <code>./start.sh</code> • Stop: <code>./stop.sh</code> • Dashboard: <code>http://127.0.0.1:8000/dashboard.php</code></p>
    </footer>
  </div>

  <script>
(function() {
  var origin = window.location.origin || 'http://127.0.0.1:8000';
  var statusEl = document.getElementById('ops-status');
  var metricPhp = document.getElementById('metric-php');
  var metricRr = document.getElementById('metric-rr');

  function setStatus(msg) {
    statusEl.textContent = msg || '';
  }

  function fetchStats() {
    return fetch(origin + '/dashboard.php?json=1')
      .then(function(r) { return r.ok ? r.json() : {}; })
      .catch(function() { return {}; });
  }

  function refreshMetrics() {
    fetchStats().then(function(s) {
      metricPhp.textContent = s.php_requests != null ? s.php_requests : 0;
      metricRr.textContent = s.roadrunner_requests != null ? s.roadrunner_requests : 0;
    });
  }

  function requestPhp(n) {
    n = n || 1;
    var promises = [];
    for (var i = 0; i < n; i++) promises.push(fetch(origin + '/'));
    return Promise.all(promises);
  }

  function requestRr(n) {
    n = n || 1;
    var promises = [];
    for (var i = 0; i < n; i++) promises.push(fetch(origin + '/request.php?target=rr'));
    return Promise.all(promises);
  }

  document.getElementById('op-php').addEventListener('click', function() {
    var btn = this;
    btn.disabled = true;
    setStatus('Sending 1 request to PHP server…');
    requestPhp(1).then(function() {
      refreshMetrics();
      setStatus('Done. Metrics updated.');
    }).catch(function() {
      setStatus('Request failed. Is the PHP server running on :8000?');
    }).then(function() {
      btn.disabled = false;
    });
  });

  document.getElementById('op-rr').addEventListener('click', function() {
    var btn = this;
    btn.disabled = true;
    setStatus('Sending 1 request to RoadRunner…');
    requestRr(1).then(function() {
      refreshMetrics();
      setStatus('Done. Metrics updated.');
    }).catch(function() {
      setStatus('Request failed. Is RoadRunner running on :8080?');
    }).then(function() {
      btn.disabled = false;
    });
  });

  document.getElementById('op-demo').addEventListener('click', function() {
    var btn = this;
    btn.disabled = true;
    setStatus('Running demo: 5 requests to each server…');
    Promise.all([requestPhp(5), requestRr(5)]).then(function() {
      refreshMetrics();
      setStatus('Demo done. Metrics updated.');
    }).catch(function() {
      refreshMetrics();
      setStatus('Demo finished (some requests may have failed).');
    }).then(function() {
      btn.disabled = false;
    });
  });

  refreshMetrics();
})();
  </script>
</body>
</html>
