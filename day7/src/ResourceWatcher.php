<?php

class ResourceWatcher
{
    private string $resourceIdentifier;
    private bool $isResourceActive = false;
    private string $logFilePath;

    public function __construct(string $identifier, string $logFilePath = 'logs/resource_events.log')
    {
        $this->resourceIdentifier = $identifier;
        $this->logFilePath = $logFilePath;
        $this->acquireResource();
    }

    private function acquireResource(): void
    {
        // Simulate acquiring a resource (e.g., opening a file, connecting to DB)
        // In a real system, this would be a real connection/handle.
        $this->isResourceActive = true;
        $this->log("Resource '{$this->resourceIdentifier}' acquired.");
    }

    public function doWork(): string
    {
        if (!$this->isResourceActive) {
            return "Error: Resource '{$this->resourceIdentifier}' is not active.";
        }
        $this->log("Resource '{$this->resourceIdentifier}' performing work.");
        return "Work done by: {$this->resourceIdentifier}";
    }

    public function __destruct()
    {
        // This is crucial: ensure resource is released if not explicitly done
        if ($this->isResourceActive) {
            $this->isResourceActive = false;
            $this->log("Resource '{$this->resourceIdentifier}' automatically released via __destruct.");
        }
    }

    private function log(string $message): void
    {
        if (!is_dir(dirname($this->logFilePath))) {
            mkdir(dirname($this->logFilePath), 0777, true);
        }
        file_put_contents($this->logFilePath, date('[Y-m-d H:i:s]') . " " . $message . PHP_EOL, FILE_APPEND);
    }
}
