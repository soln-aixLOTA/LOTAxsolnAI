package personalization_engine

import (
    "errors"
    "sync"

    "ai-platform/pkg/models"
    "ai-platform/internal/utils"

    log "github.com/sirupsen/logrus"
)

// Recommender defines the interface for recommendation systems.
type Recommender interface {
    Recommend(userID int, preferences models.UserPreferences) ([]models.RecommendedItem, error)
}

// HybridRecommender combines Collaborative Filtering and Content-Based Filtering.
type HybridRecommender struct {
    logger                 *log.Entry
    collaborativeFiltering Recommender
    contentBasedFiltering  Recommender
    mu                     sync.RWMutex
}

// NewHybridRecommender initializes a new HybridRecommender.
func NewHybridRecommender(cf Recommender, cbf Recommender) *HybridRecommender {
    logger := utils.GetLogger().WithField("module", "personalization_engine_hybrid_recommender")
    return &HybridRecommender{
        logger:                 logger,
        collaborativeFiltering: cf,
        contentBasedFiltering:  cbf,
    }
}

// Recommend generates recommendations by combining CF and CBF.
func (hr *HybridRecommender) Recommend(userID int, preferences models.UserPreferences) ([]models.RecommendedItem, error) {
    hr.mu.RLock()
    defer hr.mu.RUnlock()

    var wg sync.WaitGroup
    var cfRecommendations, cbfRecommendations []models.RecommendedItem
    var cfErr, cbfErr error

    wg.Add(2)

    // Collaborative Filtering
    go func() {
        defer wg.Done()
        cfRecommendations, cfErr = hr.collaborativeFiltering.Recommend(userID, preferences)
    }()

    // Content-Based Filtering
    go func() {
        defer wg.Done()
        cbfRecommendations, cbfErr = hr.contentBasedFiltering.Recommend(userID, preferences)
    }()

    wg.Wait()

    if cfErr != nil && cbfErr != nil {
        hr.logger.Errorf("Both CF and CBF failed for user %d: CF Error: %v, CBF Error: %v", userID, cfErr, cbfErr)
        return nil, errors.New("both collaborative and content-based recommendations failed")
    }

    // Merge recommendations
    recommendationMap := make(map[int]models.RecommendedItem)
    for _, item := range cfRecommendations {
        recommendationMap[item.ID] = item
    }
    for _, item := range cbfRecommendations {
        recommendationMap[item.ID] = item
    }

    // Convert map to slice
    var finalRecommendations []models.RecommendedItem
    for _, item := range recommendationMap {
        finalRecommendations = append(finalRecommendations, item)
    }

    hr.logger.Infof("Generated %d recommendations for user %d", len(finalRecommendations), userID)
    return finalRecommendations, nil
}
