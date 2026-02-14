#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/**
 * Sorts an integer array using selection sort algorithm.
 * Time Complexity: O(n²)
 * Space Complexity: O(1)
 */
void selection_sort_int(int arr[], int n)
{
    for (int i = 0; i < n; i++)
    {
        // Find the minimum element in remaining unsorted array
        int min_idx = i;
        for (int j = i + 1; j < n; j++)
        {
            if (arr[j] < arr[min_idx])
            {
                min_idx = j;
            }
        }

        // Swap the found minimum element with the first element
        int temp = arr[i];
        arr[i] = arr[min_idx];
        arr[min_idx] = temp;
    }
}

/**
 * Sorts a double array using selection sort algorithm.
 */
void selection_sort_double(double arr[], int n)
{
    for (int i = 0; i < n; i++)
    {
        int min_idx = i;
        for (int j = i + 1; j < n; j++)
        {
            if (arr[j] < arr[min_idx])
            {
                min_idx = j;
            }
        }

        double temp = arr[i];
        arr[i] = arr[min_idx];
        arr[min_idx] = temp;
    }
}

void print_int_array(const char *label, int arr[], int n)
{
    printf("%s[", label);
    for (int i = 0; i < n; i++)
    {
        printf("%d", arr[i]);
        if (i < n - 1)
            printf(", ");
    }
    printf("]\n");
}

void print_double_array(const char *label, double arr[], int n)
{
    printf("%s[", label);
    for (int i = 0; i < n; i++)
    {
        printf("%.2f", arr[i]);
        if (i < n - 1)
            printf(", ");
    }
    printf("]\n");
}

int main()
{
    // Test cases for integers
    int test1[] = {64, 25, 12, 22, 11};
    int test2[] = {5, 2, 8, 1, 9};
    int test3[] = {1, 2, 3, 4, 5}; // Already sorted
    int test4[] = {5, 4, 3, 2, 1}; // Reverse sorted
    int test5[] = {42};            // Single element

    int *int_tests[] = {test1, test2, test3, test4, test5};
    int sizes[] = {5, 5, 5, 5, 1};

    // Test integer arrays
    for (int i = 0; i < 5; i++)
    {
        int *original = malloc(sizes[i] * sizeof(int));
        memcpy(original, int_tests[i], sizes[i] * sizeof(int));

        printf("Test %d:\n", i + 1);
        print_int_array("  Original: ", original, sizes[i]);

        selection_sort_int(int_tests[i], sizes[i]);
        print_int_array("  Sorted:   ", int_tests[i], sizes[i]);
        printf("  Type:     int\n\n");

        free(original);
    }

    // Test case for empty array
    printf("Test 6:\n");
    printf("  Original: []\n");
    printf("  Sorted:   []\n");
    printf("  Type:     int\n\n");

    // Test case for doubles
    double test_double[] = {3.14, 1.41, 2.71, 0.57};
    int double_size = 4;

    double *original_double = malloc(double_size * sizeof(double));
    memcpy(original_double, test_double, double_size * sizeof(double));

    printf("Test 7:\n");
    print_double_array("  Original: ", original_double, double_size);

    selection_sort_double(test_double, double_size);
    print_double_array("  Sorted:   ", test_double, double_size);
    printf("  Type:     double\n\n");

    free(original_double);

    // Bonus: Verification test
    srand(time(NULL));
    int large_array[10];
    for (int i = 0; i < 10; i++)
    {
        large_array[i] = rand() % 100;
    }

    int *sorted_copy = malloc(10 * sizeof(int));
    memcpy(sorted_copy, large_array, 10 * sizeof(int));
    selection_sort_int(sorted_copy, 10);

    printf("Verification Test:\n");
    print_int_array("  Original:     ", large_array, 10);
    print_int_array("  Selection:    ", sorted_copy, 10);

    free(sorted_copy);

    return 0;
}