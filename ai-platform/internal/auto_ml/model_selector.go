package auto_ml

import (
	"errors"
	"sync"

	"ai-platform/internal/utils"

	log "github.com/sirupsen/logrus"
)

// ModelSelector defines the interface for selecting the best model.
type ModelSelector interface {
	SelectBestModel(metrics map[string]float64) (string, float64, error)
}

// SimpleModelSelector selects the model with the highest specified metric.
type SimpleModelSelector struct {
	logger *log.Entry
	metric string
	mu     sync.RWMutex
}

// NewSimpleModelSelector initializes a new SimpleModelSelector.
func NewSimpleModelSelector(metric string) *SimpleModelSelector {
	logger := utils.GetLogger().WithField("module", "auto_ml_model_selector")
	return &SimpleModelSelector{
		logger: logger,
		metric: metric,
	}
}

// SelectBestModel selects the model with the highest metric score.
func (ms *SimpleModelSelector) SelectBestModel(metrics map[string]float64) (string, float64, error) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	if len(metrics) == 0 {
		ms.logger.Warn("No metrics provided for model selection.")
		return "", 0, errors.New("no metrics provided")
	}

	var bestModel string
	var bestScore float64
	first := true

	for model, score := range metrics {
		if first || score > bestScore {
			bestModel = model
			bestScore = score
			first = false
		}
	}

	if bestModel == "" {
		ms.logger.Error("Failed to select the best model.")
		return "", 0, errors.New("no suitable model found")
	}

	ms.logger.Infof("Selected Best Model: %s with %s = %.4f", bestModel, ms.metric, bestScore)
	return bestModel, bestScore, nil
}
