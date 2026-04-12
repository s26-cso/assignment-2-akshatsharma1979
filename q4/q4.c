#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h> // Required for dynamic linking functions

int main() {
    char op[6]; // The string <op> is guaranteed to be at most 5 characters + 1 for null terminator
    int num1, num2;
    char lib_name[64];

    // Read lines from standard input in a loop
    // scanf returns the number of items successfully read; it will return 3 as long as valid input is provided
    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {
        
        // 1. Construct the shared library filename
        // The prompt states the library is in the current working directory.
        // We prepend "./" so dlopen knows to look in the current directory rather than system library paths.
        snprintf(lib_name, sizeof(lib_name), "./lib%s.so", op);

        // 2. Load the shared library into memory
        // RTLD_LAZY resolves symbols as the code that references them is executed.
        void *handle = dlopen(lib_name, RTLD_LAZY);
        if (!handle) {
            fprintf(stderr, "Failed to load library %s: %s\n", lib_name, dlerror());
            continue; 
        }

        // Clear any existing dlerror conditions
        dlerror(); 

        // 3. Extract the function pointer from the library
        // We define a function pointer type that matches: int op(int, int)
        typedef int (*operation_func)(int, int);
        
        // dlsym looks up the symbol (the string stored in 'op') within the loaded library
        operation_func func = (operation_func) dlsym(handle, op);
        
        char *error = dlerror();
        if (error != NULL) {
            fprintf(stderr, "Failed to find symbol %s: %s\n", op, error);
            dlclose(handle); // Clean up before continuing
            continue;
        }

        // 4. Execute the loaded function and print the result
        int result = func(num1, num2);
        printf("%d\n", result);

        // 5. CRITICAL: Unload the library from memory
        // Because a library can be 1.5GB and our limit is 2GB, we must free the 
        // memory immediately after computing the result so the next library can fit.
        dlclose(handle);
    }

    return 0;
}