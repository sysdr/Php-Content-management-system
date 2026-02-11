<?php

require __DIR__ . '/vendor/autoload.php';

use App\\KernelRegistry;
use Spiral\\RoadRunner\\Worker;
use Spiral\\RoadRunner\\Http\\PSR7Client;
use Nyholm\\Psr7\\Response;

// Create RoadRunner worker instance
$rrWorker = Worker::create();
$psr7 = new PSR7Client($rrWorker);

// Get the KernelRegistry instance (initialized once per worker process)
$kernelRegistry = KernelRegistry::getInstance();
$logger = $kernelRegistry->getLogger();
$config = $kernelRegistry->getConfig();

$logger->info("PHP Worker started and ready to accept requests.");

while ($request = $psr7->waitRequest()) {
    try {
        // Log that a request is being handled, using the pre-initialized logger
        $logger->info(sprintf(
            "Handling request %s %s. App Name: %s",
            $request->getMethod(),
            $request->getUri()->getPath(),
            $config['app_name']
        ));

        // Simulate some work
        usleep(10000); // 10ms delay

        // Create a response
        $response = new Response(
            200,
            ['Content-Type' => 'text/plain'],
            "Hello from HighScaleCMS! App Name: {$config['app_name']}, Version: {$config['version']}. Request processed at " . date('Y-m-d H:i:s') . "n"
        );

        $psr7->respond($response);
    } catch (Throwable $e) {
        $logger->error("Error processing request: " . $e->getMessage(), ['exception' => $e]);
        $psr7->respond(new Response(500, ['Content-Type' => 'text/plain'], 'Internal Server Error'));
    }
}

$logger->info("PHP Worker shutting down.");

