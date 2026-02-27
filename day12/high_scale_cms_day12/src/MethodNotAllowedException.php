<?php

namespace HighScaleCMS;

class MethodNotAllowedException extends \Exception
{
    /**
     * @var string[]
     */
    private array $allowedMethods;

    /**
     * @param string      $message
     * @param string[]    $allowedMethods
     * @param int         $code
     * @param \Throwable|null $previous
     */
    public function __construct(
        string $message,
        array $allowedMethods = [],
        int $code = 0,
        ?\Throwable $previous = null
    ) {
        parent::__construct($message, $code, $previous);
        $this->allowedMethods = array_values(array_unique(array_map('strtoupper', $allowedMethods)));
    }

    /**
     * @return string[]
     */
    public function getAllowedMethods(): array
    {
        return $this->allowedMethods;
    }
}

