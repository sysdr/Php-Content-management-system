<?php
/**
 * Terminal-style dashboard — alternative view for Day 4
 * Access: /dashboard-terminal.php
 */
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
  <title>Terminal View</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; padding: 0; background: #0d1117; color: #58a6ff; font-family: 'Consolas', 'Monaco', 'Courier New', monospace; font-size: 14px; line-height: 1.5; }
    .term { max-width: 700px; margin: 0 auto; padding: 1.5rem; }
    .prompt { color: #7ee787; }
    .cmd { color: #d2a8ff; }
    .val { color: #79c0ff; }
    .err { color: #ff7b72; }
    .line { margin: 0.25rem 0; }
    h1 { color: #58a6ff; font-size: 1rem; margin: 0 0 1rem; }
    #output { white-space: pre-wrap; word-break: break-all; }
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
    <h1>═══ Worker Metrics ═══</h1>
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
