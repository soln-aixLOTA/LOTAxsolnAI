# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
import argparse
import time
from src.models.model import GPT4oModel

def benchmark(n, iterations):
    model = GPT4oModel()
    start_time = time.time()
    for _ in range(iterations):
        model.predict("Sample input")
    end_time = time.time()
    total_time = end_time - start_time
    print(f"Total time for {iterations} predictions: {total_time} seconds")
    print(f"Average time per prediction: {total_time / iterations:.6f} seconds")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Benchmark Performance")
    parser.add_argument("--n", type=int, default=1000, help="Number of predictions")
    parser.add_argument("--iterations", type=int, default=10000, help="Number of iterations")
    args = parser.parse_args()
    benchmark(args.n, args.iterations)
