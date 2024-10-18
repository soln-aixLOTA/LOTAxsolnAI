package personalization_engine

import (
    "errors"
    "sync"

    "ai-platform/pkg/models"
    "ai-platform/internal/utils"

    log "github.com/sirupsen/logrus"
)

// UserPreferenceAnalyzer analyzes user interactions to extract preferences.
type UserPreferenceAnalyzer struct {
    logger           *log.Entry
    mu               sync.RWMutex
    // In-memory storage for user interactions. In production, consider persistent storage.
    userInteractions map[int][]models.UserInteraction
}

// NewUserPreferenceAnalyzer initializes a new UserPreferenceAnalyzer.
func NewUserPreferenceAnalyzer() *UserPreferenceAnalyzer {
    logger := utils.GetLogger().WithField("module", "personalization_engine_user_preference_analyzer")
    return &UserPreferenceAnalyzer{
        logger:           logger,
        userInteractions: make(map[int][]models.UserInteraction),
    }
}

// AddInteraction records a new user interaction.
func (upa *UserPreferenceAnalyzer) AddInteraction(userID int, interaction models.UserInteraction) {
    upa.mu.Lock()
    defer upa.mu.Unlock()
    upa.userInteractions[userID] = append(upa.userInteractions[userID], interaction)
    upa.logger.Infof("Added interaction for user %d: %+v", userID, interaction)
}

// AnalyzePreferences derives user preferences based on interactions.
func (upa *UserPreferenceAnalyzer) AnalyzePreferences(userID int) (models.UserPreferences, error) {
    upa.mu.RLock()
    defer upa.mu.RUnlock()

    interactions, exists := upa.userInteractions[userID]
    if !exists || len(interactions) == 0 {
        upa.logger.Warnf("No interactions found for user %d", userID)
        return models.UserPreferences{}, errors.New("no interactions found")
    }

    // Example analysis: Count actions per category
    categoryCounts := make(map[string]int)
    for _, interaction := range interactions {
        categoryCounts[interaction.Category]++
    }

    // Determine top preferred categories
    var topCategories []string
    for category, count := range categoryCounts {
        if count >= 2 { // Threshold can be adjusted
            topCategories = append(topCategories, category)
        }
    }

    preferences := models.UserPreferences{
        PreferredCategories: topCategories,
    }

    upa.logger.Infof("Analyzed preferences for user %d: %+v", userID, preferences)
    return preferences, nil
}
