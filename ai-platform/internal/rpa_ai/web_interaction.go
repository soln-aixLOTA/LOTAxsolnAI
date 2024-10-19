package rpa_ai

import (
	"context"
	"errors"
	"sync"

	"ai-platform/internal/utils"

	"github.com/chromedp/chromedp"
	log "github.com/sirupsen/logrus"
)

// WebInteractor handles complex web interactions.
type WebInteractor struct {
	logger *log.Entry
	mu     sync.RWMutex
}

// NewWebInteractor initializes a new WebInteractor.
func NewWebInteractor() *WebInteractor {
	logger := utils.GetLogger().WithField("module", "rpa_ai_web_interaction")
	return &WebInteractor{
		logger: logger,
	}
}

// PerformAdvancedAction performs an advanced action like hovering or dragging elements.
func (wi *WebInteractor) PerformAdvancedAction(ctx context.Context, actionType, selector string) error {
	wi.mu.RLock()
	defer wi.mu.RUnlock()

	switch actionType {
	case "hover":
		err := chromedp.Run(ctx, chromedp.MouseMove(selector, chromedp.ByQuery))
		if err != nil {
			wi.logger.Errorf("Failed to hover over selector %s: %v", selector, err)
			return err
		}
	case "drag":
		// Placeholder: Implement drag-and-drop logic
		wi.logger.Warn("Drag action not implemented.")
		return errors.New("drag action not implemented")
	default:
		wi.logger.Warnf("Unsupported advanced action type: %s", actionType)
		return errors.New("unsupported action type")
	}

	wi.logger.Infof("Performed %s action on selector %s", actionType, selector)
	return nil
}
