# shellcheck disable=SC2006
# Makefile

.PHONY: setup build test docker benchmark clean lint

setup:
	./scripts/setup_project.sh

build:
	docker-compose -f docker/docker-compose.yml up --build -d

test:
	docker exec -it gpt4o_finetuning_project_app pytest

docker:
	docker build -t "dislove/gpt4o_finetuning_project:latest" .

benchmark:
	python3 scripts/benchmark_performance.py --n 1000 --iterations 10000

clean:
	docker-compose -f docker/docker-compose.yml down --rmi all --volumes --remove-orphans
	rm -rf build/ dist/ *.egg-info
	find . -type d -name "__pycache__" -exec rm -r {} +
	find . -type f -name "*.pyc" -delete

lint:
	pip3 install flake8 black bandit
	flake8 src/ tests/
	black --check src/ tests/
	bandit -r src/
