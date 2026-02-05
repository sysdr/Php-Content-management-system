<?php

require __DIR__ . '/vendor/autoload.php';

use Nyholm\Psr7\Response;
use Nyholm\Psr7\Factory\Psr17Factory;
use Spiral\RoadRunner\Worker;
use Spiral\RoadRunner\Http\PSR7Worker;

$worker = Worker::create();
$factory = new Psr17Factory();
$psr7 = new PSR7Worker($worker, $factory, $factory, $factory);

$statsFile = __DIR__ . '/data/stats.json';

while (true) {
    try {
        $request = $psr7->waitRequest();
        if ($request === null) {
            break;
        }
    } catch (Throwable $e) {
        $psr7->respond(new Response(400));
        continue;
    }
    try {
        usleep(10000);
        $data = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
        $data['roadrunner_requests'] = ($data['roadrunner_requests'] ?? 0) + 1;
        @file_put_contents($statsFile, json_encode($data), LOCK_EX);
        $body = "Hello from persistent worker! " . date('Y-m-d H:i:s');
        $psr7->respond(new Response(200, [], $body));
    } catch (Throwable $e) {
        $psr7->respond(new Response(500, [], 'Error'));
        $psr7->getWorker()->error((string)$e);
    }
}
