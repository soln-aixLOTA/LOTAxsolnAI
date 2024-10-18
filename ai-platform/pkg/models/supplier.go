package models

type Supplier struct {
    ID          int     `json:"id"`
    Name        string  `json:"name"`
    Reliability float64 `json:"reliability"` // Score between 0 and 1
    RiskScore   float64 `json:"risk_score"`  // Computed risk score
}
