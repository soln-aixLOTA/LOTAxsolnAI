# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
# docs/troubleshooting.md

# Troubleshooting

This section provides solutions to common issues encountered while setting up or using the GPT-4 Fine-Tuning Project.

## Common Issues

### 1. Fine-Tuning Job Fails

**Symptoms:**
- Fine-tuning job status changes to `failed`.
- Error messages in the logs indicating invalid training data.

**Solutions:**
- **Check Training Data Format:** Ensure your training data is in the correct JSONL format.
- **Review Error Logs:** Access the fine-tuning job logs via OpenAI's dashboard to identify specific errors.
- **Validate JSONL File:** Use a JSON validator to ensure there are no syntax errors in your training data.

### 2. API Returns 401 Unauthorized

**Symptoms:**
- Accessing protected endpoints without a valid JWT token.

**Solutions:**
- **Ensure Token is Included:** Include the `Authorization: Bearer <your_jwt_token>` header in your requests.
- **Validate Token:** Ensure that the JWT token is correctly generated and not expired.
- **Check Secret Key:** Verify that the `JWT_SECRET` is correctly set in your environment variables and matches the one used to generate the tokens.

### 3. SSL Certificate Errors

**Symptoms:**
- Browser warnings about insecure connections.
- API requests failing due to SSL verification errors.

**Solutions:**
- **Use Trusted Certificates:** Ensure that you're using SSL certificates from a trusted CA in production.
- **Certificate Paths:** Verify that the SSL certificate paths in `nginx.conf` are correct.
- **Renew Certificates:** If using Let's Encrypt, ensure that your certificates are renewed before expiration.

### 4. Dependency Issues

**Symptoms:**
- Errors during installation of Python packages or building C++/Cython modules.

**Solutions:**
- **Check Requirements:** Ensure all dependencies listed in `requirements.txt` are correctly installed.
- **C++ Compiler:** Verify that a C++ compiler is installed on your system for building extensions.
- **PyBind11:** Ensure that `pybind11` is installed and correctly referenced in `setup.py`.

## Getting Further Help

If you encounter issues not covered in this guide:

1. **Check the GitHub Issues:** Search for similar problems in the [Issues](https://github.com/dislovemartin/gpt4o_finetuning_project/issues) section.
2. **Open a New Issue:** Provide detailed information about the problem, including error messages and steps to reproduce.
3. **Contact Maintainers:** Reach out to project maintainers or contributors for assistance.

---
