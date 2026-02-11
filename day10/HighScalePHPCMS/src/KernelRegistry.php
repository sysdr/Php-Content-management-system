<?php

namespace App;

use Psr\\Log\\LoggerInterface;
use Monolog\\Logger;
use Monolog\\Handler\\StreamHandler;
use Spiral\\RoadRunner\\Worker;

class KernelRegistry
{
    private static ?self $instance = null;
    private array $config;
    private LoggerInterface $logger;

    private function __construct()
    {
        // Simulate expensive, one-time bootstrap operations
        $this->config = [
            'app_name' => 'HighScaleCMS',
            'version' => '1.0.0',
            'db_connection_string' => 'mysql:host=localhost;dbname=cms',
            'cache_ttl' => 3600,
            'boot_timestamp' => microtime(true), // To prove it's initialized once
        ];

        // Logger setup (Monolog)
        // For RoadRunner, logging to stderr is often preferred for worker output
        $this->logger = new Logger('AppLogger');
        $this->logger->pushHandler(new StreamHandler('php://stderr', Logger::INFO));

        // This message should only appear ONCE per worker lifecycle
        $this->logger->info("KernelRegistry initialized ONCE at " . date('Y-m-d H:i:s', (int)$this->config['boot_timestamp']));
    }

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function getConfig(): array
    {
        return $this->config;
    }

    public function getLogger(): LoggerInterface
    {
        return $this->logger;
    }

    // Prevent cloning the instance
    private function __clone() {}

    // Prevent unserializing the instance
    public function __wakeup()
    {
        throw new \\Exception("Cannot unserialize a singleton.");
    }
}
