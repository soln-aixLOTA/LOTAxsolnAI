package personalization_engine

import (
    "errors"
    "strings"
    "sync"

    "ai-platform/pkg/models"
    "ai-platform/internal/utils"

    log "github.com/sirupsen/logrus"
)

// ContentBasedFilteringRecommender implements the Recommender interface using Content-Based Filtering.
type ContentBasedFilteringRecommender struct {
    logger       *log.Entry
    itemFeatures map[int]map[string]float64 // itemID -> feature -> value
    mu           sync.RWMutex
}

// NewContentBasedFilteringRecommender initializes a new ContentBasedFilteringRecommender.
func NewContentBasedFilteringRecommender() *ContentBasedFilteringRecommender {
    logger := utils.GetLogger().WithField("module", "personalization_engine_content_based_filtering")
    return &ContentBasedFilteringRecommender{
        logger:       logger,
        itemFeatures: make(map[int]map[string]float64),
    }
}

// AddItemFeatures records features for an item.
func (cbfr *ContentBasedFilteringRecommender) AddItemFeatures(itemID int, features map[string]float64) {
    cbfr.mu.Lock()
    defer cbfr.mu.Unlock()
    cbfr.itemFeatures[itemID] = features
    cbfr.logger.Infof("Added features for item %d", itemID)
}

// Recommend generates recommendations based on Content-Based Filtering.
func (cbfr *ContentBasedFilteringRecommender) Recommend(userID int, preferences models.UserPreferences) ([]models.RecommendedItem, error) {
    cbfr.mu.RLock()
    defer cbfr.mu.RUnlock()

    if len(preferences.PreferredCategories) == 0 {
        cbfr.logger.Warnf("No preferred categories found for user %d in CBF", userID)
        return nil, errors.New("no preferred categories found for user in content-based filtering")
    }

    // Recommend items matching preferred categories
    recommendedItems := []models.RecommendedItem{}
    for itemID, features := range cbfr.itemFeatures {
        for _, category := range preferences.PreferredCategories {
            key := "category_" + strings.ReplaceAll(category, " ", "_")
            if val, exists := features[key]; exists && val > 0 {
                recommendedItems = append(recommendedItems, models.RecommendedItem{
                    ID:    itemID,
                    Score: features["popularity"],
                })
                break
            }
        }
    }

    cbfr.logger.Infof("CBF generated %d recommendations for user %d", len(recommendedItems), userID)
    return recommendedItems, nil
}
