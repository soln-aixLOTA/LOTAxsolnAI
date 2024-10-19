package ai_chatbot

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"sync"
	"time"

	"github.com/yourusername/ai-platform/internal/config"

	"ai-platform/internal/utils"

	"github.com/chromedp/chromedp"
	log "github.com/sirupsen/logrus"
)

type Chatbot struct {
	config     *config.AIChatbotConfig
	logger     *log.Entry
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

// NewChatbot initializes a new Chatbot.
// Chatbot function: Handles chatbot interactions with users
func NewChatbot(cfg *config.AIChatbotConfig) *Chatbot {
	logger := utils.GetLogger().WithField("module", "ai_chatbot")
	return &Chatbot{
		config: cfg,
		logger: logger,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// GenerateText generates text based on the provided prompt.
// Chatbot function: Handles chatbot interactions with users
func (cb *Chatbot) GenerateText(prompt string) (string, error) {
	cb.mu.RLock()
	defer cb.mu.RUnlock()

	if prompt == "" {
		cb.logger.Warn("Empty prompt provided for text generation.")
		return "", fmt.Errorf("empty prompt")
	}

	requestBody := OpenAITextRequest{
		Model:       "gpt-4",
		Prompt:      prompt,
		MaxTokens:   200,
		Temperature: 0.7,
	}

	data, err := json.Marshal(requestBody)
	if err != nil {
		cb.logger.Errorf("Failed to marshal text generation request: %v", err)
		return "", err
	}

	req, err := http.NewRequest("POST", "https://api.openai.com/v1/completions", bytes.NewBuffer(data))
	if err != nil {
		cb.logger.Errorf("Failed to create HTTP request: %v", err)
		return "", err
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", cb.config.OpenAIAPIKey))
	req.Header.Set("Content-Type", "application/json")

	resp, err := cb.httpClient.Do(req)
	if err != nil {
		cb.logger.Errorf("HTTP request failed: %v", err)
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := ioutil.ReadAll(resp.Body)
		cb.logger.Errorf("OpenAI API error: %d - %s", resp.StatusCode, string(bodyBytes))
		return "", fmt.Errorf("OpenAI API error: %d - %s", resp.StatusCode, string(bodyBytes))
	}

	var openAIResp OpenAITextResponse
	if err := json.NewDecoder(resp.Body).Decode(&openAIResp); err != nil {
		cb.logger.Errorf("Failed to decode OpenAI response: %v", err)
		return "", err
	}

	if len(openAIResp.Choices) == 0 {
		cb.logger.Warn("OpenAI response contains no choices.")
		return "", fmt.Errorf("no text generated")
	}

	generatedText := openAIResp.Choices[0].Text
	cb.logger.Infof("Generated Text: %s", generatedText)
	return generatedText, nil
}

// AutomateChatbotInteraction automates interactions with a web-based chatbot using chromedp.
// Chatbot function: Handles chatbot interactions with users
func (cb *Chatbot) AutomateChatbotInteraction(prompt string) (string, error) {
	cb.mu.RLock()
	defer cb.mu.RUnlock()

	ctx, cancel := chromedp.NewContext(context.Background())
	defer cancel()

	var response string

	tasks := chromedp.Tasks{
		chromedp.Navigate("https://your-chatbot-url.com"),
		chromedp.WaitVisible(`#chat-input`, chromedp.ByID),
		chromedp.SendKeys(`#chat-input`, prompt+"\n", chromedp.ByID),
		chromedp.Sleep(2 * time.Second), // Wait for response
		chromedp.Text(`#chat-response`, &response, chromedp.ByID),
	}

	if err := chromedp.Run(ctx, tasks); err != nil {
		cb.logger.Errorf("chromedp tasks failed: %v", err)
		return "", err
	}

	cb.logger.Infof("Chatbot responded with: %s", response)
	return response, nil
}
