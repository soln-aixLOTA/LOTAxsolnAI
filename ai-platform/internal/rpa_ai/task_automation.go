package rpa_ai

import (
	"context"
	"errors"
	"sync"
	"time"

	"ai-platform/internal/utils"

	"github.com/chromedp/chromedp"
	log "github.com/sirupsen/logrus"
)

// Task represents a generic automation task.
type Task struct {
	Name     string
	Selector string
	Action   string // e.g., "click", "fill", "select"
	Value    string // value to fill if Action is "fill"
}

// TaskAutomation automates a series of tasks.
type TaskAutomation struct {
	logger *log.Entry
	tasks  []Task
	mu     sync.RWMutex
}

// NewTaskAutomation initializes a new TaskAutomation.
func NewTaskAutomation() *TaskAutomation {
	logger := utils.GetLogger().WithField("module", "rpa_ai_task_automation")
	return &TaskAutomation{
		logger: logger,
		tasks:  []Task{},
	}
}

// AddTask adds a new task to the automation sequence.
func (ta *TaskAutomation) AddTask(task Task) {
	ta.mu.Lock()
	defer ta.mu.Unlock()
	ta.tasks = append(ta.tasks, task)
	ta.logger.Infof("Added task: %s", task.Name)
}

// ExecuteTasks executes all added tasks.
func (ta *TaskAutomation) ExecuteTasks(url string) error {
	ta.mu.RLock()
	defer ta.mu.RUnlock()

	if len(ta.tasks) == 0 {
		ta.logger.Warn("No tasks to execute.")
		return errors.New("no tasks to execute")
	}

	ctx, cancel := chromedp.NewContext(context.Background())
	defer cancel()

	// Navigate to the target URL
	err := chromedp.Run(ctx, chromedp.Navigate(url))
	if err != nil {
		ta.logger.Errorf("Failed to navigate to URL %s: %v", url, err)
		return err
	}

	// Iterate over tasks and execute them
	for _, task := range ta.tasks {
		ta.logger.Infof("Executing task: %s", task.Name)
		switch task.Action {
		case "click":
			err = chromedp.Run(ctx, chromedp.Click(task.Selector, chromedp.ByQuery))
			if err != nil {
				ta.logger.Errorf("Failed to click on selector %s: %v", task.Selector, err)
				return err
			}
		case "fill":
			err = chromedp.Run(ctx, chromedp.SendKeys(task.Selector, task.Value, chromedp.ByQuery))
			if err != nil {
				ta.logger.Errorf("Failed to fill selector %s with value %s: %v", task.Selector, task.Value, err)
				return err
			}
		case "select":
			err = chromedp.Run(ctx, chromedp.SetValue(task.Selector, task.Value, chromedp.ByQuery))
			if err != nil {
				ta.logger.Errorf("Failed to select value %s for selector %s: %v", task.Value, task.Selector, err)
				return err
			}
		default:
			ta.logger.Warnf("Unsupported action %s for task %s", task.Action, task.Name)
		}

		// Optional: Wait between tasks to allow for page updates
		time.Sleep(1 * time.Second)
	}

	ta.logger.Info("All tasks executed successfully.")
	return nil
}
