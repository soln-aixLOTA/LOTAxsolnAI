# shellcheck disable=SC2006
from setuptools import setup, Extension
from Cython.Build import cythonize
import pybind11
import os

extensions = [
    Extension(
        "src.optimizations.cpp_modules.math_operations",
        ["src/optimizations/cpp_modules/math_operations.cpp"],
        include_dirs=[pybind11.get_include()],
        language='c++'
    ),
    Extension(
        "src.optimizations.cython_modules.math_operations",
        ["src/optimizations/cython_modules/math_operations.pyx"],
        include_dirs=[pybind11.get_include()],
        language='c++'
    )
]

setup(
    name="gpt4o_finetuning_project",
    version="1.0.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="gpt-4o Fine-Tuning Project with Cython, C++, and Go optimizations.",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    packages=["src", "src.optimizations.cython_modules", "src.optimizations.cpp_modules", "src.optimizations.go_service"],
    ext_modules=cythonize(extensions),
    install_requires=[
        # Add your Python dependencies here
        "fastapi",
        "uvicorn",
        "openai",
        "jose",
        "hvac",
        # ... other dependencies
    ],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.9',
)
