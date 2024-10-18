package personalization_engine

import (
    "errors"
    "sync"

    "ai-platform/pkg/models"
    "ai-platform/internal/utils"

    log "github.com/sirupsen/logrus"
)

// CollaborativeFilteringRecommender implements the Recommender interface using Collaborative Filtering.
type CollaborativeFilteringRecommender struct {
    logger         *log.Entry
    userItemMatrix map[int]map[int]float64 // userID -> itemID -> interaction score
    mu             sync.RWMutex
}

// NewCollaborativeFilteringRecommender initializes a new CollaborativeFilteringRecommender.
func NewCollaborativeFilteringRecommender() *CollaborativeFilteringRecommender {
    logger := utils.GetLogger().WithField("module", "personalization_engine_collaborative_filtering")
    return &CollaborativeFilteringRecommender{
        logger:         logger,
        userItemMatrix: make(map[int]map[int]float64),
    }
}

// AddUserInteraction records an interaction between a user and an item.
func (cfr *CollaborativeFilteringRecommender) AddUserInteraction(userID, itemID int, score float64) {
    cfr.mu.Lock()
    defer cfr.mu.Unlock()
    if _, exists := cfr.userItemMatrix[userID]; !exists {
        cfr.userItemMatrix[userID] = make(map[int]float64)
    }
    cfr.userItemMatrix[userID][itemID] = score
    cfr.logger.Infof("Added interaction: User %d - Item %d (Score: %.2f)", userID, itemID, score)
}

// Recommend generates recommendations based on Collaborative Filtering.
func (cfr *CollaborativeFilteringRecommender) Recommend(userID int, preferences models.UserPreferences) ([]models.RecommendedItem, error) {
    cfr.mu.RLock()
    defer cfr.mu.RUnlock()

    userInteractions, exists := cfr.userItemMatrix[userID]
    if !exists || len(userInteractions) == 0 {
        cfr.logger.Warnf("No interactions found for user %d in CF", userID)
        return nil, errors.New("no interactions found for user in collaborative filtering")
    }

    // Placeholder: Implement a simple similarity-based recommendation
    // For demonstration, recommend top N items not interacted with by the user
    // In production, use matrix factorization or more advanced techniques

    recommendedItems := []models.RecommendedItem{}
    // Example: Recommend items with the highest average scores across all users
    itemScores := make(map[int]float64)
    itemCounts := make(map[int]int)

    for _, interactions := range cfr.userItemMatrix {
        for itemID, score := range interactions {
            if _, interacted := userInteractions[itemID]; !interacted {
                itemScores[itemID] += score
                itemCounts[itemID]++
            }
        }
    }

    for itemID, totalScore := range itemScores {
        avgScore := totalScore / float64(itemCounts[itemID])
        recommendedItems = append(recommendedItems, models.RecommendedItem{
            ID:    itemID,
            Score: avgScore,
        })
    }

    // Sort recommended items by score in descending order
    // Placeholder: Implement sorting logic
    // For brevity, skipping sorting

    cfr.logger.Infof("CF generated %d recommendations for user %d", len(recommendedItems), userID)
    return recommendedItems, nil
}
