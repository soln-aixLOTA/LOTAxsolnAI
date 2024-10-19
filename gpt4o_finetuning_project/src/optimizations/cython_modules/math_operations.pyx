# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
# cython: language_level=3

from src.optimizations.cpp_modules.math_operations import reverse_string

def cython_reverse_string(str input):
    """
    Reverses the input string using the C++ extension.
    """
    return reverse_string(input)
