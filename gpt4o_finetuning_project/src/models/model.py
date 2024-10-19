# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
import openai
import os
from typing import Optional, Dict, Any
import time

class GPT4oModel:
    def __init__(self):
        # Initialize the model with OpenAI API key
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY is not set in environment variables.")
        openai.api_key = self.api_key

    def upload_training_file(self, file_path: str, purpose: str = "fine-tune") -> str:
        """
        Uploads a training file to OpenAI.
        :param file_path: Path to the training JSONL file.
        :param purpose: The purpose of the file upload. Default is 'fine-tune'.
        :return: The file ID.
        """
        try:
            response = openai.File.create(
                file=open(file_path, "rb"),
                purpose=purpose
            )
            file_id = response['id']
            print(f"Training file uploaded. File ID: {file_id}")
            return file_id
        except Exception as e:
            print(f"Error uploading training file: {e}")
            raise

    def fine_tune(self, training_file_id: str, model_name: str = "davinci") -> str:
        """
        Initiates a fine-tuning job.
        :param training_file_id: The ID of the uploaded training file.
        :param model_name: The base model to fine-tune.
        :return: The Fine-tune ID.
        """
        try:
            response = openai.FineTune.create(
                training_file=training_file_id,
                model=model_name,
                n_epochs=4,
                batch_size=8,
                learning_rate_multiplier=0.1,
                prompt_loss_weight=0.01,
                compute_classification_metrics=False
            )
            fine_tune_id = response['id']
            print(f"Fine-tuning initiated. Fine-tune ID: {fine_tune_id}")
            return fine_tune_id
        except Exception as e:
            print(f"Error initiating fine-tuning: {e}")
            raise

    def get_fine_tune_status(self, fine_tune_id: str) -> Dict[str, Any]:
        """
        Retrieves the status of a fine-tuning job.
        :param fine_tune_id: The ID of the fine-tuning job.
        :return: A dictionary containing the fine-tuning status.
        """
        try:
            response = openai.FineTune.retrieve(id=fine_tune_id)
            status = response['status']
            print(f"Fine-tune ID: {fine_tune_id} Status: {status}")
            return response
        except Exception as e:
            print(f"Error retrieving fine-tuning status: {e}")
            raise

    def wait_for_fine_tuning(self, fine_tune_id: str, poll_interval: int = 60):
        """
        Waits for the fine-tuning job to complete.
        :param fine_tune_id: The ID of the fine-tuning job.
        :param poll_interval: Time in seconds between status checks.
        """
        print(f"Waiting for fine-tuning job {fine_tune_id} to complete...")
        while True:
            status_response = self.get_fine_tune_status(fine_tune_id)
            status = status_response['status']
            if status in ['succeeded', 'failed']:
                print(f"Fine-tuning job {fine_tune_id} completed with status: {status}")
                break
            print(f"Current status: {status}. Checking again in {poll_interval} seconds...")
            time.sleep(poll_interval)

    def predict(self, prompt: str, model: Optional[str] = None) -> str:
        """
        Generates a prediction using the fine-tuned GPT-4o model.
        :param prompt: Input text for prediction.
        :param model: The fine-tuned model to use. If None, uses the base model.
        :return: Generated prediction.
        """
        try:
            selected_model = model if model else "davinci"
            response = openai.Completion.create(
                model=selected_model,
                prompt=prompt,
                max_tokens=150,
                temperature=0.7,
                top_p=1,
                frequency_penalty=0,
                presence_penalty=0
            )
            prediction = response.choices[0].text.strip()
            return prediction
        except Exception as e:
            print(f"Error during prediction: {e}")
            raise
