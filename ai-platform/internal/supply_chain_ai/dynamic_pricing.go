package supply_chain_ai

import (
    "errors"
    "fmt"
    "strconv"
    "sync"

    "ai-platform/internal/utils"
    "ai-platform/pkg/models"

    log "github.com/sirupsen/logrus"
)

// DynamicPricingModel adjusts product prices based on demand and supply factors.
type DynamicPricingModel struct {
    logger        *log.Entry
    mu            sync.RWMutex
    productPrices map[int]float64 // productID -> current price
}

// NewDynamicPricingModel initializes a new DynamicPricingModel.
func NewDynamicPricingModel() *DynamicPricingModel {
    logger := utils.GetLogger().WithField("module", "supply_chain_ai_dynamic_pricing")
    return &DynamicPricingModel{
        logger:        logger,
        productPrices: make(map[int]float64),
    }
}

// LoadProductPrices loads current product prices.
func (dpm *DynamicPricingModel) LoadProductPrices(prices []models.ProductPrice) {
    dpm.mu.Lock()
    defer dpm.mu.Unlock()
    for _, price := range prices {
        parsedPrice, err := strconv.ParseFloat(price.Price, 64)
        if err != nil {
            dpm.logger.Errorf("Failed to parse price for Product ID %d: %v", price.ProductID, err)
            continue
        }
        dpm.productPrices[price.ProductID] = parsedPrice
    }
    dpm.logger.Infof("Loaded prices for %d products.", len(prices))
}

// AdjustPrices adjusts prices based on demand forecasts.
func (dpm *DynamicPricingModel) AdjustPrices(demands []models.Demand) ([]models.ProductPrice, error) {
    dpm.mu.RLock()
    defer dpm.mu.RUnlock()

    if len(demands) == 0 {
        dpm.logger.Warn("No demand data provided for price adjustment.")
        return nil, errors.New("no demand data")
    }

    adjustedPrices := []models.ProductPrice{}
    for _, demand := range demands {
        currentPrice, exists := dpm.productPrices[demand.ProductID]
        if !exists {
            dpm.logger.Warnf("Price not found for Product ID %d. Skipping.", demand.ProductID)
            continue
        }

        // Placeholder: Implement a simple price adjustment based on demand.
        // Example: If demand > threshold, increase price by 5%
        //           else, decrease price by 3%

        threshold := 100.0
        var newPrice float64
        if demand.Quantity > threshold {
            newPrice = currentPrice * 1.05
        } else {
            newPrice = currentPrice * 0.97
        }

        adjustedPrices = append(adjustedPrices, models.ProductPrice{
            ProductID: demand.ProductID,
            Price:     fmt.Sprintf("%.2f", newPrice),
        })

        dpm.logger.Infof("Adjusted price for Product ID %d: Old Price=%.2f, New Price=%.2f", demand.ProductID, currentPrice, newPrice)
    }

    return adjustedPrices, nil
}
