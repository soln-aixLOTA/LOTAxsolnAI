package supply_chain_ai

import (
	"errors"
	"sync"

	"ai-platform/internal/utils"
	"ai-platform/pkg/models"

	log "github.com/sirupsen/logrus"
)

// InventoryOptimizer optimizes inventory levels based on demand forecasts and lead times.
type InventoryOptimizer struct {
	logger         *log.Entry
	mu             sync.RWMutex
	inventoryData  []models.Inventory
	demandForecast []models.Demand
}

// NewInventoryOptimizer initializes a new InventoryOptimizer.
func NewInventoryOptimizer() *InventoryOptimizer {
	logger := utils.GetLogger().WithField("module", "supply_chain_ai_inventory_optimizer")
	return &InventoryOptimizer{
		logger: logger,
	}
}

// LoadInventoryData loads current inventory data.
func (io *InventoryOptimizer) LoadInventoryData(data []models.Inventory) {
	io.mu.Lock()
	defer io.mu.Unlock()
	io.inventoryData = data
	io.logger.Infof("Loaded %d inventory records.", len(data))
}

// LoadDemandForecast loads demand forecast data.
func (io *InventoryOptimizer) LoadDemandForecast(forecast []models.Demand) {
	io.mu.Lock()
	defer io.mu.Unlock()
	io.demandForecast = forecast
	io.logger.Infof("Loaded %d demand forecast records.", len(forecast))
}

// OptimizeInventory calculates optimal inventory levels.
func (io *InventoryOptimizer) OptimizeInventory() ([]models.Inventory, error) {
	io.mu.RLock()
	defer io.mu.RUnlock()

	if len(io.inventoryData) == 0 || len(io.demandForecast) == 0 {
		io.logger.Warn("Insufficient data for inventory optimization.")
		return nil, errors.New("insufficient data")
	}

	optimizedInventory := []models.Inventory{}
	for _, inv := range io.inventoryData {
		forecast, exists := findDemandForecast(io.demandForecast, inv.ProductID)
		if !exists {
			io.logger.Warnf("No demand forecast found for Product ID %d.", inv.ProductID)
			continue
		}

		// Simple optimization: Stock level = forecast demand + safety stock
		safetyStock := 10.0 // This can be dynamic based on variability
		optimalStock := forecast.Quantity + safetyStock

		optimizedInventory = append(optimizedInventory, models.Inventory{
			ProductID: inv.ProductID,
			Quantity:  optimalStock,
		})
		io.logger.Infof("Optimized inventory for Product ID %d: %.2f", inv.ProductID, optimalStock)
	}

	return optimizedInventory, nil
}

// findDemandForecast retrieves demand forecast for a specific product.
func findDemandForecast(forecast []models.Demand, productID int) (models.Demand, bool) {
	for _, f := range forecast {
		if f.ProductID == productID {
			return f, true
		}
	}
	return models.Demand{}, false
}
