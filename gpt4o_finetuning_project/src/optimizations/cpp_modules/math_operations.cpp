# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
#include <pybind11/pybind11.h>
#include <string>

namespace py = pybind11;

// Example function: Reverse a string
std::string reverse_string(const std::string &input) {
    std::string reversed(input.rbegin(), input.rend());
    return reversed;
}

PYBIND11_MODULE(math_operations, m) {
    m.doc() = "C++ extension module for GPT-4o fine-tuning project";
    m.def("reverse_string", &reverse_string, "A function that reverses a string");
}
