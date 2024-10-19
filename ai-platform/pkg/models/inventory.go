package models

type Inventory struct {
    ProductID int     `json:"product_id"`
    Quantity  float64 `json:"quantity"`
}

type Demand struct {
    ProductID int     `json:"product_id"`
    Quantity  float64 `json:"quantity"`
}

type ProductPrice struct {
    ProductID int    `json:"product_id"`
    Price     string `json:"price"` // Formatted as a string for precision
}
