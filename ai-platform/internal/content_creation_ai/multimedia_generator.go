package content_creation_ai

import (
    "bytes"
    "encoding/json"
    "errors"
    "fmt"
    "io/ioutil"
    "net/http"
    "sync"

    "ai-platform/internal/config"
    "ai-platform/internal/utils"

    log "github.com/sirupsen/logrus"
)

type MultimediaGenerator struct {
    logger     *log.Entry
    config     *config.ContentCreationAIConfig
    httpClient *http.Client
    mu         sync.RWMutex
}

type SpeechRequest struct {
    Text         string `json:"text"`
    Voice        string `json:"voice"`
    AudioFormat  string `json:"audio_format"`
    SampleRateHz int    `json:"sample_rate_hz"`
}

type SpeechResponse struct {
    AudioURL string `json:"audio_url"`
}

// NewMultimediaGenerator initializes a new MultimediaGenerator.
func NewMultimediaGenerator(cfg *config.ContentCreationAIConfig) *MultimediaGenerator {
    logger := utils.GetLogger().WithField("module", "content_creation_ai_multimedia_generator")
    return &MultimediaGenerator{
        logger:     logger,
        config:     cfg,
        httpClient: &http.Client{},
    }
}

// GenerateSpeech generates speech audio based on the provided text.
func (mg *MultimediaGenerator) GenerateSpeech(text, voice string) (string, error) {
    mg.mu.RLock()
    defer mg.mu.RUnlock()

    if text == "" {
        mg.logger.Warn("Empty text provided for speech generation.")
        return "", errors.New("empty text")
    }

    requestBody := SpeechRequest{
        Text:         text,
        Voice:        voice,
        AudioFormat:  "mp3",
        SampleRateHz: 44100,
    }

    data, err := json.Marshal(requestBody)
    if err != nil {
        mg.logger.Errorf("Failed to marshal speech generation request: %v", err)
        return "", err
    }

    req, err := http.NewRequest("POST", "https://api.speecht5.com/v1/synthesize", bytes.NewBuffer(data))
    if err != nil {
        mg.logger.Errorf("Failed to create HTTP request: %v", err)
        return "", err
    }

    req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", mg.config.SpeechAPIKey))
    req.Header.Set("Content-Type", "application/json")

    resp, err := mg.httpClient.Do(req)
    if err != nil {
        mg.logger.Errorf("HTTP request failed: %v", err)
        return "", err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        bodyBytes, _ := ioutil.ReadAll(resp.Body)
        mg.logger.Errorf("Speech API error: %d - %s", resp.StatusCode, string(bodyBytes))
        return "", fmt.Errorf("Speech API error: %d - %s", resp.StatusCode, string(bodyBytes))
    }

    var speechResp SpeechResponse
    if err := json.NewDecoder(resp.Body).Decode(&speechResp); err != nil {
        mg.logger.Errorf("Failed to decode Speech API response: %v", err)
        return "", err
    }

    if speechResp.AudioURL == "" {
        mg.logger.Warn("Speech API response contains no audio URL.")
        return "", errors.New("no audio generated")
    }

    mg.logger.Infof("Generated Speech Audio URL: %s", speechResp.AudioURL)
    return speechResp.AudioURL, nil
}
