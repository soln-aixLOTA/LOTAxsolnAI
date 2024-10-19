package content_creation_ai

import (
    "errors"
    "sync"

    "ai-platform/internal/utils"

    log "github.com/sirupsen/logrus"
)

// ContentCreationManager orchestrates the content creation processes.
type ContentCreationManager struct {
    logger          *log.Entry
    textGenerator   *TextGenerator
    imageGenerator  *ImageGenerator
    multimediaGen   *MultimediaGenerator
    mu              sync.RWMutex
}

// NewContentCreationManager initializes a new ContentCreationManager.
func NewContentCreationManager(tg *TextGenerator, ig *ImageGenerator, mg *MultimediaGenerator) *ContentCreationManager {
    logger := utils.GetLogger().WithField("module", "content_creation_ai_manager")
    return &ContentCreationManager{
        logger:         logger,
        textGenerator:  tg,
        imageGenerator: ig,
        multimediaGen:  mg,
    }
}

// CreateContent generates text, image, and audio based on the input prompt.
func (ccm *ContentCreationManager) CreateContent(prompt string) (string, []string, string, error) {
    ccm.mu.RLock()
    defer ccm.mu.RUnlock()

    if prompt == "" {
        ccm.logger.Warn("Empty prompt provided for content creation.")
        return "", nil, "", errors.New("empty prompt")
    }

    // Generate Text
    text, err := ccm.textGenerator.GenerateText(prompt)
    if err != nil {
        ccm.logger.Errorf("Text generation failed: %v", err)
        return "", nil, "", err
    }

    // Generate Image
    imageURLs, err := ccm.imageGenerator.GenerateImage(prompt)
    if err != nil {
        ccm.logger.Errorf("Image generation failed: %v", err)
        return "", nil, "", err
    }

    // Generate Audio
    audioURL, err := ccm.multimediaGen.GenerateSpeech(text, "en-US-Wavenet-D")
    if err != nil {
        ccm.logger.Errorf("Audio generation failed: %v", err)
        return "", nil, "", err
    }

    ccm.logger.Info("Content creation completed successfully.")
    return text, imageURLs, audioURL, nil
}
