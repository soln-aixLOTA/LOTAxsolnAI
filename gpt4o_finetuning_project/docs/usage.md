# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
# docs/usage.md

# Usage Instructions

This guide explains how to use the GPT-4o Fine-Tuning Project.

## API Endpoints

- **GET /api/health**

  Health check endpoint.

- **POST /api/fine-tune**

  Endpoint to fine-tune the GPT-4o model.

- **POST /api/predict**

  Endpoint to get predictions from the fine-tuned model.

- **GET /api/status**

  Retrieves the status of a specific fine-tuning job.

## Authentication

All endpoints require JWT authentication. Include the JWT token in the `Authorization` header:

```
Authorization: Bearer your_jwt_token
```

## Example Requests

- **Fine-Tuning the Model:**

  ```bash
  curl -X POST "http://localhost:8000/api/fine-tune" \
       -H "Authorization: Bearer your_jwt_token" \
       -H "Content-Type: application/json" \
       -d '{"training_file_id": "file-12345"}'
  ```

- **Getting Predictions:**

  ```bash
  curl -X POST "http://localhost:8000/api/predict" \
       -H "Authorization: Bearer your_jwt_token" \
       -H "Content-Type: application/json" \
       -d '{"text": "Your input text here"}'
  ```

- **Checking Fine-Tuning Job Status:**

  ```bash
  curl -X GET "http://localhost:8000/api/status?fine_tune_id=ft-12345" \
       -H "Authorization: Bearer your_jwt_token"
  ```

---
