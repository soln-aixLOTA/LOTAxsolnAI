package models

type User struct {
    ID       int    `json:"id"`
    Username string `json:"username"`
    Email    string `json:"email"`
    // Add additional fields as needed
}

type UserInteraction struct {
    ItemID   int
    Action   string // e.g., "view", "click", "purchase"
    Category string
}

type UserPreferences struct {
    PreferredCategories []string
}

type RecommendedItem struct {
    ID    int     `json:"id"`
    Score float64 `json:"score"`
}
