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

type ImageGenerator struct {
    logger     *log.Entry
    config     *config.ContentCreationAIConfig
    httpClient *http.Client
    mu         sync.RWMutex
}

type OpenAIImageRequest struct {
    Prompt         string `json:"prompt"`
    N              int    `json:"n"`
    Size           string `json:"size"`
    ResponseFormat string `json:"response_format"`
}

type OpenAIImageResponse struct {
    Data []struct {
        URL string `json:"url"`
    } `json:"data"`
}

// NewImageGenerator initializes a new ImageGenerator.
func NewImageGenerator(cfg *config.ContentCreationAIConfig) *ImageGenerator {
    logger := utils.GetLogger().WithField("module", "content_creation_ai_image_generator")
    return &ImageGenerator{
        logger:     logger,
        config:     cfg,
        httpClient: &http.Client{},
    }
}

// GenerateImage generates an image based on the provided prompt.
func (ig *ImageGenerator) GenerateImage(prompt string) ([]string, error) {
    ig.mu.RLock()
    defer ig.mu.RUnlock()

    if prompt == "" {
        ig.logger.Warn("Empty prompt provided for image generation.")
        return nil, errors.New("empty prompt")
    }

    requestBody := OpenAIImageRequest{
        Prompt:         prompt,
        N:              1,
        Size:           "512x512",
        ResponseFormat: "url",
    }

    data, err := json.Marshal(requestBody)
    if err != nil {
        ig.logger.Errorf("Failed to marshal image generation request: %v", err)
        return nil, err
    }

    req, err := http.NewRequest("POST", "https://api.openai.com/v1/images/generations", bytes.NewBuffer(data))
    if err != nil {
        ig.logger.Errorf("Failed to create HTTP request: %v", err)
        return nil, err
    }

    req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", ig.config.OpenAIAPIKey))
    req.Header.Set("Content-Type", "application/json")

    resp, err := ig.httpClient.Do(req)
    if err != nil {
        ig.logger.Errorf("HTTP request failed: %v", err)
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        bodyBytes, _ := ioutil.ReadAll(resp.Body)
        ig.logger.Errorf("OpenAI Image API error: %d - %s", resp.StatusCode, string(bodyBytes))
        return nil, fmt.Errorf("OpenAI Image API error: %d - %s", resp.StatusCode, string(bodyBytes))
    }

    var openAIResp OpenAIImageResponse
    if err := json.NewDecoder(resp.Body).Decode(&openAIResp); err != nil {
        ig.logger.Errorf("Failed to decode OpenAI Image response: %v", err)
        return nil, err
    }

    if len(openAIResp.Data) == 0 {
        ig.logger.Warn("OpenAI Image response contains no data.")
        return nil, errors.New("no image generated")
    }

    imageURLs := []string{}
    for _, img := range openAIResp.Data {
        imageURLs = append(imageURLs, img.URL)
    }

    ig.logger.Infof("Generated Image URLs: %+v", imageURLs)
    return imageURLs, nil
}
