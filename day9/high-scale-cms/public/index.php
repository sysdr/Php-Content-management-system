<?php

// This static variable will persist across requests within the same FrankenPHP worker
static  = 0;
++;

// Get the process ID to verify we're hitting the same process
 = getmypid();

// Simulate some work or data fetching
usleep(10000); // 10ms delay

echo "<h1>Welcome to High-Scale CMS!</h1>";
echo "<p>This is request number <strong>" .  . "</strong> served by PHP process ID: <strong>" .  . "</strong></p>";
echo "<p>Current time: " . date('Y-m-d H:i:s') . "</p>";
echo "<p>Learn more about FrankenPHP: <a href="https://frankenphp.dev" target="_blank">frankenphp.dev</a></p>";

// Optional: Force memory usage to demonstrate potential issues if not careful
//  = array_fill(0, 100000, str_repeat('a', 100)); // Uncomment to see memory grow
// unset(); // Essential to clean up if used
?>
