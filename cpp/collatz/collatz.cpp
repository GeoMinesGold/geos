#include <iostream>
#include <gmp.h>
#include <vector>
#include <string>
#include <cstdlib>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <sstream>
#include <functional>
#include <regex>

// Mutex, condition variable, and atomic for thread synchronization
std::mutex value_mutex;
std::condition_variable cv;
std::atomic<bool> finished(false);

// Shared Collatz value and step counter
mpz_t current_value;
int step_counter = 0;

// Function to parse an operation like "nx + c" or "n / k"
std::function<void(mpz_t)> parse_operation(const std::string& operation) {
    // Regular expression to match the form nx + c or n / k
    std::regex mul_add_regex("^([+-]?[0-9]+)x\\s*([+-]\\s*[0-9]+)$");
    std::regex div_regex("^n\\s*/\\s*([0-9]+)$");

    std::smatch match;
    std::function<void(mpz_t)> parsed_op;

    // Check if the operation matches "nx + c"
    if (std::regex_match(operation, match, mul_add_regex)) {
        int multiplier = std::stoi(match[1].str());
        int constant = std::stoi(match[2].str());

        parsed_op = [multiplier, constant](mpz_t n) {
            mpz_mul_ui(n, n, multiplier);  // Multiply by the multiplier
            mpz_add_ui(n, n, constant);    // Add the constant
        };
    }
    // Check if the operation matches "n / k"
    else if (std::regex_match(operation, match, div_regex)) {
        int divisor = std::stoi(match[1].str());

        parsed_op = [divisor](mpz_t n) {
            mpz_divexact_ui(n, n, divisor); // Divide by the divisor
        };
    }
    else {
        std::cerr << "Unrecognized operation: " << operation << std::endl;
        exit(EXIT_FAILURE);
    }

    return parsed_op;
}

// Thread function for Collatz sequence
void collatz_sequence(int thread_id, int num_threads, std::function<void(mpz_t)> odd_op, std::function<void(mpz_t)> even_op) {
    while (true) {
        mpz_t n;

        mpz_init(n);

        {
            // Lock the mutex to access and modify shared resources
            std::unique_lock<std::mutex> lock(value_mutex);
            cv.wait(lock, [thread_id, num_threads]() {
                return (step_counter % num_threads) == thread_id || finished;
            });

            if (finished) {
                mpz_clear(n);
                return; // Exit if processing is finished
            }

            // Copy current value to local n
            mpz_set(n, current_value);

            // Check if n has reached 1
            if (mpz_cmp_ui(n, 1) == 0) {
                std::cout << step_counter << ": " << "1" << std::endl;
                finished = true; // Signal that we're done
                cv.notify_all();
                mpz_clear(n);
                return;
            }

            // Print current step and value
            char* n_str = mpz_get_str(NULL, 10, n);
            std::cout << step_counter << ": " << n_str << std::endl;
            free(n_str);

            // Apply the correct operation based on even or odd
            if (mpz_even_p(n)) {
                even_op(n);  // Apply even operation
            } else {
                odd_op(n);   // Apply odd operation
            }

            // Update the shared current value and step counter
            mpz_set(current_value, n);
            step_counter++;
        }

        // Notify the next waiting thread
        cv.notify_all();

        // Clear local n after use
        mpz_clear(n);
    }
}

int main(int argc, char* argv[]) {
    if (argc < 4) {
        std::cerr << "Usage: " << argv[0] << " <odd operation> <even operation> <starting value>" << std::endl;
        return EXIT_FAILURE;
    }

    std::string odd_op_str(argv[1]);
    std::string even_op_str(argv[2]);
    std::string input(argv[3]);

    // Parse the custom operations
    auto odd_op = parse_operation(odd_op_str);
    auto even_op = parse_operation(even_op_str);

    // Initialize GMP integer for the starting value
    mpz_init(current_value);
    if (mpz_set_str(current_value, input.c_str(), 10) != 0) {
        std::cerr << "Invalid input: " << input << std::endl;
        mpz_clear(current_value);
        return EXIT_FAILURE;
    }

    // Get the number of hardware threads available
    unsigned int num_threads = std::thread::hardware_concurrency();
    std::vector<std::thread> threads;

    // Start worker threads
    for (unsigned int i = 0; i < num_threads; ++i) {
        threads.emplace_back(collatz_sequence, i, num_threads, odd_op, even_op);
    }

    // Wait for all threads to finish
    for (auto& thread : threads) {
        thread.join();
    }

    // Clean up
    mpz_clear(current_value);

    return EXIT_SUCCESS;
}
