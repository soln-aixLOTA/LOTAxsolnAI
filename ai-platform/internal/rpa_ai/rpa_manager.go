package rpa_ai

import (
	"context"

	"ai-platform/internal/utils"

	"github.com/chromedp/chromedp"
	log "github.com/sirupsen/logrus"
)

// RPAManager orchestrates the RPA processes.
type RPAManager struct {
	logger         *log.Entry
	taskAutomation *TaskAutomation
	webInteractor  *WebInteractor
}

// NewRPAManager initializes a new RPAManager.
func NewRPAManager() *RPAManager {
	logger := utils.GetLogger().WithField("module", "rpa_ai_manager")
	return &RPAManager{
		logger:         logger,
		taskAutomation: NewTaskAutomation(),
		webInteractor:  NewWebInteractor(),
	}
}

// RunAutomation runs the entire RPA automation sequence.
func (rm *RPAManager) RunAutomation(url string) error {
	rm.logger.Info("Starting RPA automation sequence.")

	// Example: Define a series of tasks
	tasks := []Task{
		{
			Name:     "Login",
			Selector: "#username",
			Action:   "fill",
			Value:    "myUsername",
		},
		{
			Name:     "Login Password",
			Selector: "#password",
			Action:   "fill",
			Value:    "myPassword",
		},
		{
			Name:     "Submit Login",
			Selector: "#submit-button",
			Action:   "click",
			Value:    "",
		},
		{
			Name:     "Navigate to Dashboard",
			Selector: "#dashboard-link",
			Action:   "click",
			Value:    "",
		},
		// Add more tasks as needed
	}

	for _, task := range tasks {
		rm.taskAutomation.AddTask(task)
	}

	// Execute the tasks
	err := rm.taskAutomation.ExecuteTasks(url)
	if err != nil {
		rm.logger.Errorf("Task automation failed: %v", err)
		return err
	}

	// Perform advanced actions if necessary
	// Example: Hover over a menu item
	ctx, cancel := chromedp.NewContext(context.Background())
	defer cancel()

	err = rm.webInteractor.PerformAdvancedAction(ctx, "hover", "#menu-item")
	if err != nil {
		rm.logger.Errorf("Advanced web interaction failed: %v", err)
		return err
	}

	rm.logger.Info("RPA automation sequence completed successfully.")
	return nil
}
