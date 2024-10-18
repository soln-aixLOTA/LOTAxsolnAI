package supply_chain_ai

import (
    "bytes"
    "encoding/json"
    "errors"
    "fmt"
    "net/http"
    "sync"
    "time"

    "ai-platform/internal/config"
    "ai-platform/internal/utils"
    "ai-platform/pkg/models"

    log "github.com/sirupsen/logrus"
)

// ERPIntegration manages communication with the ERP system.
type ERPIntegration struct {
    logger     *log.Entry
    config     *config.ERPConfig
    httpClient *http.Client
    mu         sync.RWMutex
}

// NewERPIntegration initializes a new ERPIntegration.
func NewERPIntegration(cfg *config.ERPConfig) *ERPIntegration {
    logger := utils.GetLogger().WithField("module", "supply_chain_ai_erp_integration")
    return &ERPIntegration{
        logger: logger,
        config: cfg,
        httpClient: &http.Client{
            Timeout: 30 * time.Second,
        },
    }
}

// SendInventoryUpdates sends optimized inventory data to the ERP system.
func (eri *ERPIntegration) SendInventoryUpdates(inventory []models.Inventory) error {
    eri.mu.RLock()
    defer eri.mu.RUnlock()

    if len(inventory) == 0 {
        eri.logger.Warn("No inventory data to send to ERP.")
        return errors.New("no inventory data")
    }

    url := eri.config.Endpoint + "/api/inventory/update"
    payload, err := json.Marshal(inventory)
    if err != nil {
        eri.logger.Errorf("Failed to marshal inventory data: %v", err)
        return err
    }

    req, err := http.NewRequest("POST", url, bytes.NewBuffer(payload))
    if err != nil {
        eri.logger.Errorf("Failed to create ERP HTTP request: %v", err)
        return err
    }

    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", eri.config.APIKey))

    resp, err := eri.httpClient.Do(req)
    if err != nil {
        eri.logger.Errorf("Failed to send inventory updates to ERP: %v", err)
        return err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        eri.logger.Errorf("ERP responded with status code %d", resp.StatusCode)
        return fmt.Errorf("ERP API error: %d", resp.StatusCode)
    }

    eri.logger.Infof("Successfully sent inventory updates to ERP.")
    return nil
}
