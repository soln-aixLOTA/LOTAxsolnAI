package content_creation_ai

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"sync"

	"ai-platform/internal/utils"

	"ai-platform/internal/config"

	log "github.com/sirupsen/logrus"
)

type TextGenerator struct {
	logger     *log.Entry
	config     *config.ContentCreationAIConfig
	httpClient *http.Client
	mu         sync.RWMutex
}

type OpenAITextRequest struct {
	Model       string  `json:"model"`
	Prompt      string  `json:"prompt"`
	MaxTokens   int     `json:"max_tokens"`
	Temperature float64 `json:"temperature"`
}

type OpenAITextResponse struct {
	Choices []struct {
		Text string `json:"text"`
	} `json:"choices"`
}

// NewTextGenerator initializes a new TextGenerator.
func NewTextGenerator(cfg *config.ContentCreationAIConfig) *TextGenerator {
	logger := utils.GetLogger().WithField("module", "content_creation_ai_text_generator")
	return &TextGenerator{
		logger:     logger,
		config:     cfg,
		httpClient: &http.Client{},
	}
}

// GenerateText generates text based on the provided prompt.
func (tg *TextGenerator) GenerateText(prompt string) (string, error) {
	tg.mu.RLock()
	defer tg.mu.RUnlock()

	if prompt == "" {
		tg.logger.Warn("Empty prompt provided for text generation.")
		return "", errors.New("empty prompt")
	}

	requestBody := OpenAITextRequest{
		Model:       "gpt-4",
		Prompt:      prompt,
		MaxTokens:   200,
		Temperature: 0.7,
	}

	data, err := json.Marshal(requestBody)
	if err != nil {
		tg.logger.Errorf("Failed to marshal text generation request: %v", err)
		return "", err
	}

	req, err := http.NewRequest("POST", "https://api.openai.com/v1/completions", bytes.NewBuffer(data))
	if err != nil {
		tg.logger.Errorf("Failed to create HTTP request: %v", err)
		return "", err
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", tg.config.OpenAIAPIKey))
	req.Header.Set("Content-Type", "application/json")

	resp, err := tg.httpClient.Do(req)
	if err != nil {
		tg.logger.Errorf("HTTP request failed: %v", err)
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := ioutil.ReadAll(resp.Body)
		tg.logger.Errorf("OpenAI API error: %d - %s", resp.StatusCode, string(bodyBytes))
		return "", fmt.Errorf("OpenAI API error: %d - %s", resp.StatusCode, string(bodyBytes))
	}

	var openAIResp OpenAITextResponse
	if err := json.NewDecoder(resp.Body).Decode(&openAIResp); err != nil {
		tg.logger.Errorf("Failed to decode OpenAI response: %v", err)
		return "", err
	}

	if len(openAIResp.Choices) == 0 {
		tg.logger.Warn("OpenAI response contains no choices.")
		return "", errors.New("no text generated")
	}

	generatedText := openAIResp.Choices[0].Text
	tg.logger.Infof("Generated Text: %s", generatedText)
	return generatedText, nil
}
