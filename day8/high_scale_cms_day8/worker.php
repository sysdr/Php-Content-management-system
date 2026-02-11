<?php

declare(strict_types=1);

// Global flags to control worker behavior
$shutdown_initiated = false;
$reload_config = false;
$worker_name = "PHP-CMS-Worker-" . substr(md5((string)time()), 0, 6);

// --- Signal Handler Function ---
function signalHandler(int $signo): void
{
    global $shutdown_initiated, $reload_config, $worker_name;

    switch ($signo) {
        case SIGTERM:
            echo "n�33[0;33m[SIGNAL]�33[0m Worker PID " . getmypid() . ": SIGTERM received. Initiating graceful shutdown...n";
            $shutdown_initiated = true;
            break;
        case SIGHUP:
            echo "n�33[0;36m[SIGNAL]�33[0m Worker PID " . getmypid() . ": SIGHUP received. Reloading configuration...n";
            // Simulate configuration reload by changing the worker name
            $worker_name = "PHP-CMS-Worker-RELOADED-" . substr(md5((string)time()), 0, 6);
            $reload_config = true; // Set flag to indicate reload for main loop
            break;
        case SIGINT:
            echo "n�33[0;33m[SIGNAL]�33[0m Worker PID " . getmypid() . ": SIGINT received. Initiating graceful shutdown...n";
            $shutdown_initiated = true;
            break;
        default:
            echo "n�33[0;35m[SIGNAL]�33[0m Worker PID " . getmypid() . ": Received unknown signal $signo.n";
            break;
    }
}

// --- Main Worker Logic ---
function runWorker(): void
{
    global $shutdown_initiated, $reload_config, $worker_name;

    // Enable asynchronous signal handling
    // This allows PHP to check for signals even when executing userland code (like sleep())
    pcntl_async_signals(true);

    // Register signal handlers
    pcntl_signal(SIGTERM, "signalHandler");
    pcntl_signal(SIGHUP, "signalHandler");
    pcntl_signal(SIGINT, "signalHandler"); // For Ctrl+C in console

    echo "�33[0;32m[START]�33[0m Worker PID " . getmypid() . " started with name: $worker_name.n";
    echo "         (To test: find PID, then 'kill -TERM <PID>' for shutdown or 'kill -HUP <PID>' for config reload)n";
    echo "         (For Docker: 'docker kill -s TERM php-cms-worker-container' or 'docker kill -s HUP php-cms-worker-container')n";

    $request_counter = 0;
    while (!$shutdown_initiated) {
        // Dispatch pending signals. This is crucial for signals to be processed
        // while the script is busy or sleeping.
        pcntl_signal_dispatch();

        // Simulate config reload if SIGHUP was received
        if ($reload_config) {
            echo "�33[0;36m[CONFIG]�33[0m Worker PID " . getmypid() . ": Applied new configuration. Worker name: $worker_name.n";
            // Reset the flag after processing the reload
            $reload_config = false;
        }

        $request_counter++;
        echo "�33[0;34m[WORK]�33[0m [$worker_name] Worker PID " . getmypid() . ": Processing request #$request_counter...n";
        
        // Simulate real work that takes time (e.g., database query, API call)
        sleep(2); 

        // Dispatch signals again in case one arrived during sleep
        pcntl_signal_dispatch();
    }

    echo "�33[0;33m[SHUTDOWN]�33[0m Worker PID " . getmypid() . ": All pending requests processed. Performing final cleanup...n";
    sleep(1); // Simulate cleanup tasks (e.g., flushing logs, closing connections)
    echo "�33[0;32m[EXIT]�33[0m Worker PID " . getmypid() . ": Exiting gracefully.n";
    exit(0);
}

// Ensure pcntl extension is loaded
if (!extension_loaded('pcntl')) {
    echo "�33[0;31m[ERROR]�33[0m PCNTL extension is not loaded. Please enable it in your php.ini.n";
    exit(1);
}

// Start the worker
runWorker();

