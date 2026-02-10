<?php

// Enable explicit garbage collection for demonstration purposes
gc_enable();

class LeakyParent {
    public $children = [];
    public $id;
    public $data; // Add some data to make objects larger

    public function __construct($id) {
        $this->id = $id;
        $this->data = str_repeat('A', 1024); // 1KB of data
    }

    public function addChild(LeakyChild $child) {
        $this->children[] = $child;
    }
}

class LeakyChild {
    public $parent;
    public $id;
    public $data; // Add some data to make objects larger

    public function __construct($id, LeakyParent $parent) {
        $this->id = $id;
        $this->parent = $parent; // THIS IS THE CIRCULAR REFERENCE
        $this->data = str_repeat('B', 512); // 0.5KB of data
    }
}

// A static container to *deliberately* hold references, ensuring a leak for the demo.
// In a real app, this might be a cache, a global registry, or static properties.
class LeakyContainer {
    public static $leakedObjects = [];
}

// --- Main application logic ---
echo "--- Starting Memory Leak Simulation ---\n";
echo "Initial Memory: " . round(memory_get_usage() / (1024 * 1024), 2) . " MB\n";

$iterations = 1000; // Number of objects to create and leak
$gc_interval = 200; // Call gc_collect_cycles() every N iterations

for ($i = 0; $i < $iterations; $i++) {
    $parent = new LeakyParent($i);
    $child = new LeakyChild($i, $parent);
    $parent->addChild($child);

    // Deliberately leak the parent object by storing it in a static array.
    // This prevents PHP's default reference counting from freeing it,
    // and creates a persistent circular reference via $child->parent.
    LeakyContainer::$leakedObjects[] = $parent;

    if (($i + 1) % $gc_interval === 0 || $i === $iterations - 1) {
        echo "Iteration " . ($i + 1) . " (of $iterations) - Current Memory: " . round(memory_get_usage() / (1024 * 1024), 2) . " MB";

        $collected = gc_collect_cycles(); // Manually trigger cyclic GC
        echo " | After gc_collect_cycles() (Collected: $collected cycles): " . round(memory_get_usage() / (1024 * 1024), 2) . " MB\n";

        // Important insight: Even after gc_collect_cycles(), memory still grows significantly
        // because LeakyContainer::$leakedObjects[] holds a direct reference to $parent,
        // preventing the *entire cycle* from being garbage collected.
        // The cycle is A (parent) -> B (child) -> A (parent).
        // LeakyContainer::$leakedObjects[] -> A (parent).
        // Because LeakyContainer::$leakedObjects[] is still reachable, the parent (A) is reachable.
        // Therefore, the child (B) is also reachable. The cycle is NOT "isolated garbage".
        // This demonstrates that gc_collect_cycles() only works on *unreachable* cycles.
        // Our demo intentionally makes the cycle reachable via the static property.
        // A *true* leak that gc_collect_cycles() would fix is if LeakyContainer::$leakedObjects
        // wasn't holding a reference, but the objects A and B still referenced each other
        // and nothing else referenced A or B.
        // For this demo, we aim to show memory *growth* despite GC attempts, indicating a persistent leak.
    }
}

echo "--- Simulation Complete ---\n";
echo "Final Memory: " . round(memory_get_usage() / (1024 * 1024), 2) . " MB\n";
echo "Peak Memory: " . round(memory_get_peak_usage() / (1024 * 1024), 2) . " MB\n";

// Optional: Clear the static array to demonstrate final memory release if needed
// unset(LeakyContainer::$leakedObjects);
// echo "Memory after clearing static reference: " . round(memory_get_usage() / (1024 * 1024), 2) . " MBn";

?>
