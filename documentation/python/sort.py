import numpy as np


def selection_sort(arr):
    """
    Sorts a numpy array using selection sort algorithm.

    Time Complexity: O(n²)
    Space Complexity: O(1)
    """
    n = len(arr)

    for i in range(n):
        # Find the minimum element in remaining unsorted array
        min_idx = i + np.argmin(arr[i:])

        # Swap the found minimum element with the first element
        arr[i], arr[min_idx] = arr[min_idx], arr[i]

    return arr


def main():
    # Test cases using numpy arrays
    test_cases = [
        np.array([64, 25, 12, 22, 11]),
        np.array([5, 2, 8, 1, 9]),
        np.array([1, 2, 3, 4, 5]),  # Already sorted
        np.array([5, 4, 3, 2, 1]),  # Reverse sorted
        np.array([42]),  # Single element
        np.array([]),  # Empty array
        np.array([3.14, 1.41, 2.71, 0.57]),  # Floats
    ]

    for i, test in enumerate(test_cases, 1):
        original = test.copy()
        sorted_arr = selection_sort(test)
        print(f"Test {i}:")
        print(f"  Original: {original}")
        print(f"  Sorted:   {sorted_arr}")
        print(f"  Type:     {sorted_arr.dtype}")
        print()

    # Bonus: Compare with numpy's built-in sort
    large_array = np.random.randint(0, 100, size=10)
    print("Verification Test:")
    print(f"  Original:     {large_array}")
    print(f"  Selection:    {selection_sort(large_array.copy())}")
    print(f"  NumPy sort:   {np.sort(large_array)}")


if __name__ == "__main__":
    main()
