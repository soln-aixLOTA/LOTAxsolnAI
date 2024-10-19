package ai_chatbot

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io/ioutil"
    "net/http"
    "sync"
    "time"

    "github.com/soln-aixLOTA/LOTAxsolnAI/internal/config"

    log "github.com/sirupsen/logrus"
)

type AIClient struct {
    config     config.ModelConfig
    httpClient *http.Client
    logger     *log.Entry
    mu         sync.RWMutex
}

type InferenceRequest struct {
    Inputs     string                 `json:"inputs"`
    Parameters map[string]interface{} `json:"parameters,omitempty"`
}

type InferenceResponse struct {
    GeneratedText string `json:"generated_text"`
    // Add other fields based on the response structure
}

// NewAIClient initializes a new AIClient.
func NewAIClient(cfg config.ModelConfig) *AIClient {
    logger := log.WithFields(log.Fields{
        "module": "ai_chatbot_client",
    })

    return &AIClient{
        config: cfg,
        httpClient: &http.Client{
            Timeout: 60 * time.Second,
        },
        logger: logger,
    }
}

// GenerateText sends a prompt to the model and returns the generated text.
func (c *AIClient) GenerateText(prompt string) (string, error) {
    c.mu.RLock()
    defer c.mu.RUnlock()

    if prompt == "" {
        c.logger.Warn("Empty prompt provided for text generation.")
        return "", fmt.Errorf("empty prompt")
    }

    requestBody := InferenceRequest{
        Inputs: prompt,
        Parameters: map[string]interface{}{
            "max_new_tokens": 200,
            "temperature":    0.7,
        },
    }

    data, err := json.Marshal(requestBody)
    if err != nil {
        c.logger.Errorf("Failed to marshal inference request: %v", err)
        return "", err
    }

    req, err := http.NewRequest("POST", c.config.InferenceURL, bytes.NewBuffer(data))
    if err != nil {
        c.logger.Errorf("Failed to create HTTP request: %v", err)
        return "", err
    }

    req.Header.Set("Content-Type", "application/json")
    if c.config.APIKey != "" {
        req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.config.APIKey))
    }

    resp, err := c.httpClient.Do(req)
    if err != nil {
        c.logger.Errorf("HTTP request failed: %v", err)
        return "", err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        bodyBytes, _ := ioutil.ReadAll(resp.Body)
        c.logger.Errorf("Inference API error: %d - %s", resp.StatusCode, string(bodyBytes))
        return "", fmt.Errorf("inference API error: %d - %s", resp.StatusCode, string(bodyBytes))
    }

    var inferenceResp InferenceResponse
    if err := json.NewDecoder(resp.Body).Decode(&inferenceResp); err != nil {
        c.logger.Errorf("Failed to decode inference response: %v", err)
        return "", err
    }

    if inferenceResp.GeneratedText == "" {
        c.logger.Warn("Inference response contains no generated text.")
        return "", fmt.Errorf("no text generated")
    }

    c.logger.Infof("Generated Text: %s", inferenceResp.GeneratedText)
    return inferenceResp.GeneratedText, nil
}
