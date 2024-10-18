package unit

import (
    "testing"

    "ai-platform/internal/personalization_engine"
    "ai-platform/pkg/models"
)

func TestAnalyzePreferences(t *testing.T) {
    analyzer := personalization_engine.NewUserPreferenceAnalyzer()

    // Add interactions
    analyzer.AddInteraction(1, models.UserInteraction{ItemID: 101, Action: "view", Category: "Electronics"})
    analyzer.AddInteraction(1, models.UserInteraction{ItemID: 102, Action: "purchase", Category: "Books"})
    analyzer.AddInteraction(1, models.UserInteraction{ItemID: 103, Action: "view", Category: "Electronics"})

    preferences, err := analyzer.AnalyzePreferences(1)
    if err != nil {
        t.Errorf("Expected no error, got %v", err)
    }

    expectedCategories := []string{"Electronics", "Books"}
    if len(preferences.PreferredCategories) != len(expectedCategories) {
        t.Errorf("Expected %d preferred categories, got %d", len(expectedCategories), len(preferences.PreferredCategories))
    }

    # Further assertions can be added to verify the content of PreferredCategories
}
