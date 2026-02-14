/**
 * Sorts an array using selection sort algorithm.
 * Time Complexity: O(n²)
 * Space Complexity: O(1)
 */
function selectionSort(arr) {
    const n = arr.length;

    for (let i = 0; i < n; i++) {
        // Find the minimum element in remaining unsorted array
        let minIdx = i;
        for (let j = i + 1; j < n; j++) {
            if (arr[j] < arr[minIdx]) {
                minIdx = j;
            }
        }

        // Swap the found minimum element with the first element
        [arr[i], arr[minIdx]] = [arr[minIdx], arr[i]];
    }

    return arr;
}

function getType(arr) {
    if (arr.length === 0) return 'empty';
    return arr.every(n => Number.isInteger(n)) ? 'int' : 'float';
}

function main() {
    // Test cases
    const testCases = [
        [64, 25, 12, 22, 11],
        [5, 2, 8, 1, 9],
        [1, 2, 3, 4, 5],      // Already sorted
        [5, 4, 3, 2, 1],      // Reverse sorted
        [42],                  // Single element
        [],                    // Empty array
        [3.14, 1.41, 2.71, 0.57]  // Floats
    ];

    testCases.forEach((test, i) => {
        const original = [...test];
        const sortedArr = selectionSort([...test]);

        console.log(`Test ${i + 1}:`);
        console.log(`  Original: [${original}]`);
        console.log(`  Sorted:   [${sortedArr}]`);
        console.log(`  Type:     ${getType(original)}`);
        console.log();
    });

    // Bonus: Verification test
    const largeArray = Array.from({ length: 10 }, () => Math.floor(Math.random() * 100));
    const sortedCopy = selectionSort([...largeArray]);
    const jsSorted = [...largeArray].sort((a, b) => a - b);

    console.log("Verification Test:");
    console.log(`  Original:     [${largeArray}]`);
    console.log(`  Selection:    [${sortedCopy}]`);
    console.log(`  JS sort:      [${jsSorted}]`);
}

main();