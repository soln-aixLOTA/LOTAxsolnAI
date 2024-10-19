# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
import time
from src.optimizations.cython_modules.math_operations import cython_reverse_string

def pure_python_reverse(input_str):
    return input_str[::-1]

def benchmark():
    test_string = "A" * 1000000  # 1,000,000 characters

    start_time = time.time()
    pure_result = pure_python_reverse(test_string)
    pure_duration = time.time() - start_time
    print(f"Pure Python Reverse: Completed in {pure_duration:.4f} seconds")

    start_time = time.time()
    cython_result = cython_reverse_string(test_string)
    cython_duration = time.time() - start_time
    print(f"Cython-Optimized Reverse: Completed in {cython_duration:.4f} seconds")

    improvement = pure_duration / cython_duration
    print(f"Performance Improvement: {improvement:.2f}x faster")

if __name__ == "__main__":
    benchmark()
