public class SelectionSort {

    /**
     * Sorts an array using selection sort algorithm.
     * Time Complexity: O(n²)
     * Space Complexity: O(1)
     */
    public static void selectionSort(int[] arr) {
        int n = arr.length;

        for (int i = 0; i < n; i++) {
            // Find the minimum element in remaining unsorted array
            int minIdx = i;
            for (int j = i + 1; j < n; j++) {
                if (arr[j] < arr[minIdx]) {
                    minIdx = j;
                }
            }

            // Swap the found minimum element with the first element
            int temp = arr[i];
            arr[i] = arr[minIdx];
            arr[minIdx] = temp;
        }
    }

    public static void selectionSort(double[] arr) {
        int n = arr.length;

        for (int i = 0; i < n; i++) {
            int minIdx = i;
            for (int j = i + 1; j < n; j++) {
                if (arr[j] < arr[minIdx]) {
                    minIdx = j;
                }
            }

            double temp = arr[i];
            arr[i] = arr[minIdx];
            arr[minIdx] = temp;
        }
    }

    public static void main(String[] args) {
        // Test cases
        int[][] intTests = {
                { 64, 25, 12, 22, 11 },
                { 5, 2, 8, 1, 9 },
                { 1, 2, 3, 4, 5 }, // Already sorted
                { 5, 4, 3, 2, 1 }, // Reverse sorted
                { 42 }, // Single element
                {} // Empty array
        };

        double[][] doubleTests = {
                { 3.14, 1.41, 2.71, 0.57 } // Floats
        };

        // Test integer arrays
        for (int i = 0; i < intTests.length; i++) {
            int[] original = intTests[i].clone();
            int[] sorted = intTests[i].clone();
            selectionSort(sorted);

            System.out.println("Test " + (i + 1) + ":");
            System.out.println("  Original: " + arrayToString(original));
            System.out.println("  Sorted:   " + arrayToString(sorted));
            System.out.println("  Type:     int");
            System.out.println();
        }

        // Test double arrays
        for (int i = 0; i < doubleTests.length; i++) {
            double[] original = doubleTests[i].clone();
            double[] sorted = doubleTests[i].clone();
            selectionSort(sorted);

            System.out.println("Test " + (intTests.length + i + 1) + ":");
            System.out.println("  Original: " + arrayToString(original));
            System.out.println("  Sorted:   " + arrayToString(sorted));
            System.out.println("  Type:     double");
            System.out.println();
        }

        // Bonus: Verification test
        int[] largeArray = new int[10];
        for (int i = 0; i < largeArray.length; i++) {
            largeArray[i] = (int) (Math.random() * 100);
        }

        int[] sortedCopy = largeArray.clone();
        selectionSort(sortedCopy);

        int[] javaSort = largeArray.clone();
        java.util.Arrays.sort(javaSort);

        System.out.println("Verification Test:");
        System.out.println("  Original:     " + arrayToString(largeArray));
        System.out.println("  Selection:    " + arrayToString(sortedCopy));
        System.out.println("  Arrays.sort:  " + arrayToString(javaSort));
    }

    private static String arrayToString(int[] arr) {
        if (arr.length == 0)
            return "[]";
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < arr.length; i++) {
            sb.append(arr[i]);
            if (i < arr.length - 1)
                sb.append(", ");
        }
        sb.append("]");
        return sb.toString();
    }

    private static String arrayToString(double[] arr) {
        if (arr.length == 0)
            return "[]";
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < arr.length; i++) {
            sb.append(arr[i]);
            if (i < arr.length - 1)
                sb.append(", ");
        }
        sb.append("]");
        return sb.toString();
    }
}