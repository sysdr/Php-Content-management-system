<?php
// web/opcache-status.php - Displays OPcache and JIT status

echo "<h1>OPcache & JIT Status</h1>";
if (function_exists('opcache_get_status')) {
    $status = opcache_get_status(false); // Do not reset
    echo "<pre>";
    print_r($status);
    echo "</pre>";
} else {
    echo "<p>OPcache is not enabled or function opcache_get_status() is not available.</p>";
}
?>
