# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
# docs/contribution_examples.md

# Contribution Examples

This section provides examples to guide contributors in implementing features or fixes within the GPT-4 Fine-Tuning Project.

## Example 1: Adding a New API Endpoint

### Scenario:

Add a new endpoint `/api/status` that returns the current status of the fine-tuning job.

### Steps:

1. **Update API Routes:**

   **File:** `src/api/main.py`

   ```python
   @app.get("/api/status")
   async def get_status(fine_tune_id: str, current_user: str = Depends(get_current_user)):
       """
       Retrieves the status of a specific fine-tuning job.
       """
       status_response = model.get_fine_tune_status(fine_tune_id)
       return {"fine_tune_id": fine_tune_id, "status": status_response['status']}
   ```

2. **Update Tests:**

   **File:** `tests/test_api.py`

   ```python
   def test_get_status():
       # Mocking the get_fine_tune_status method
       with patch.object(GPT4oModel, 'get_fine_tune_status', return_value={'status': 'succeeded'}):
           response = client.get(
               "/api/status",
               headers={"Authorization": "Bearer your_jwt_token"},
               params={"fine_tune_id": "ft-12345"}
           )
           assert response.status_code == 200
           assert response.json() == {"fine_tune_id": "ft-12345", "status": "succeeded"}
   ```

3. **Update Documentation:**

   **File:** `docs/usage.md`

   ```markdown
   ## API Endpoints

   - **GET /api/status**
   
     Retrieves the status of a specific fine-tuning job.
   
     **Parameters:**
     - `fine_tune_id` (query): The ID of the fine-tuning job.
   
     **Example Request:**
   
     ```bash
     curl -X GET "http://localhost:8000/api/status?fine_tune_id=ft-12345" \
          -H "Authorization: Bearer your_jwt_token"
     ```
   
     **Example Response:**
   
     ```json
     {
       "fine_tune_id": "ft-12345",
       "status": "succeeded"
     }
     ```
   ```

4. **Commit and Push Changes:**

    ```bash
    git add src/api/main.py tests/test_api.py docs/usage.md
    git commit -m "Add /api/status endpoint to retrieve fine-tuning job status"
    git push origin feature/add-status-endpoint
    ```

5. **Create Pull Request:**
   - Navigate to your forked repository on GitHub.
   - Click on "Compare & pull request" for the `feature/add-status-endpoint` branch.
   - Provide a descriptive title and description for your PR.
   - Submit the pull request for review.

**Result:**

A new API endpoint `/api/status` is available, allowing users to check the status of their fine-tuning jobs. Comprehensive tests and documentation ensure reliability and ease of use.

---
