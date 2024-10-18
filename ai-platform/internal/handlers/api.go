package handlers

import (
    "encoding/json"
    "io/ioutil"
    "net/http"
)

// Structs for Chatbot API
type ChatbotRequest struct {
    Prompt string `json:"prompt"`
}

type ChatbotResponse struct {
    Message string `json:"message"`
}

// ChatbotHandler handles chatbot interactions
func ChatbotHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    var req ChatbotRequest
    body, err := ioutil.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "Bad request", http.StatusBadRequest)
        return
    }
    defer r.Body.Close()

    err = json.Unmarshal(body, &req)
    if err != nil {
        http.Error(w, "Bad request", http.StatusBadRequest)
        return
    }

    // Placeholder: Integrate with AI Chatbot logic here
    response := ChatbotResponse{Message: "Hello! How can I assist you today?"}

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

// Structs for Analytics API
type AnalyticsData struct {
    Labels []string  `json:"labels"`
    Values []float64 `json:"values"`
}

// AnalyticsDataHandler provides data for the analytics chart
func AnalyticsDataHandler(w http.ResponseWriter, r *http.Request) {
    data := AnalyticsData{
        Labels: []string{"Jan", "Feb", "Mar", "Apr", "May"},
        Values: []float64{75.5, 60.2, 90.3, 80.1, 85.6},
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(data)
}

// AnalyticsMetricHandler provides metric-specific data
func AnalyticsMetricHandler(w http.ResponseWriter, r *http.Request) {
    metric := r.URL.Path[len("/api/analytics/"):]
    var data AnalyticsData

    switch metric {
    case "risk":
        data = AnalyticsData{
            Labels: []string{"Jan", "Feb", "Mar", "Apr", "May"},
            Values: []float64{70.5, 65.2, 80.3, 75.0, 90.1},
        }
    case "performance":
        data = AnalyticsData{
            Labels: []string{"Jan", "Feb", "Mar", "Apr", "May"},
            Values: []float64{85.0, 88.5, 90.2, 87.3, 92.4},
        }
    case "engagement":
        data = AnalyticsData{
            Labels: []string{"Jan", "Feb", "Mar", "Apr", "May"},
            Values: []float64{60.0, 65.5, 70.2, 75.3, 80.4},
        }
    default:
        http.Error(w, "Metric not found", http.StatusNotFound)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(data)
}

// Structs for Contact API
type ContactRequest struct {
    Name    string `json:"name"`
    Email   string `json:"email"`
    Message string `json:"message"`
}

type ContactResponse struct {
    Message string `json:"message"`
}

// ContactHandler handles contact form submissions
func ContactHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    var req ContactRequest
    body, err := ioutil.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "Bad request", http.StatusBadRequest)
        return
    }
    defer r.Body.Close()

    err = json.Unmarshal(body, &req)
    if err != nil {
        http.Error(w, "Bad request", http.StatusBadRequest)
        return
    }

    // Placeholder: Process contact form (e.g., send email, store in DB)
    response := ContactResponse{Message: "Thank you for contacting us! We will get back to you shortly."}

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
