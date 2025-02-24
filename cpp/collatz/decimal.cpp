#include <iostream>
#include <gmp.h>
#include <regex>
#include <omp.h>  // For OpenMP parallel processing

void calculate_and_print_large_power(const char* base_str, unsigned long exponent) {
    // Initialize GMP variables
    mpz_t base, result;
    mpz_init_set_str(base, base_str, 10); // Initialize base from string
    mpz_init(result);

    // Calculate base^exponent and store in result
    mpz_pow_ui(result, base, exponent);

    // Print the result without extra newline at the end
    mpz_out_str(stdout, 10, result); // Output in base 10

    // Clean up
    mpz_clear(base);
    mpz_clear(result);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <number in scientific notation>\n";
        return 1;
    }

    std::string input_str(argv[1]);
    std::regex sci_notation_pattern(R"((\d+(\.\d+)?)[eE][+-]?(\d+))");

    // Match scientific notation
    std::smatch match;
    if (std::regex_match(input_str, match, sci_notation_pattern)) {
        std::string base_str = match[1]; // Base part (e.g., "3.7")
        unsigned long exponent = std::stoul(match[3]); // Exponent part (e.g., "12")

        // Convert the base part to an integer by shifting decimal place according to exponent
        int decimal_places = base_str.find('.') != std::string::npos 
                             ? base_str.size() - base_str.find('.') - 1 
                             : 0;

        if (decimal_places > 0) {
            base_str.erase(base_str.find('.'), 1);  // Remove decimal point
            exponent -= decimal_places; // Adjust exponent
        }

        // Use all available CPU cores
        omp_set_num_threads(omp_get_max_threads());

        // Calculate power
        #pragma omp parallel
        {
            #pragma omp single
            {
                calculate_and_print_large_power(base_str.c_str(), exponent);
            }
        }
    } else {
        std::cerr << "Invalid input format. Use standard scientific notation (e.g., 3.7e+12).\n";
        return 1;
    }

    std::cout.flush(); // Ensure all output is written out without an extra newline
    return 0;
}
