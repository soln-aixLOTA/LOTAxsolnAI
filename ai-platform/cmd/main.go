package main

import (
	"log"
	"net/http"
	"path/filepath"

	"ai-platform/internal/handlers"
)

func main() {
	fs := http.FileServer(http.Dir("./web"))
	http.Handle("/", cacheMiddleware(fs))

	// API Handlers
	http.HandleFunc("/api/chatbot", handlers.ChatbotHandler)
	http.HandleFunc("/api/analytics/data", handlers.AnalyticsDataHandler)
	http.HandleFunc("/api/analytics/", handlers.AnalyticsMetricHandler)
	http.HandleFunc("/api/contact", handlers.ContactHandler)
	// Add more handlers as needed

	// SPA Routes - serve index.html for known SPA routes
	spaRoutes := []string{"/", "/dashboard", "/chatbot", "/analytics", "/about", "/contact"}
	for _, route := range spaRoutes {
		http.HandleFunc(route, serveIndex)
	}

	// Start the server
	log.Println("Serving on :8080...")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal(err)
	}
}

// serveIndex serves the index.html for SPA routes
func serveIndex(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, filepath.Join("./web", "index.html"))
}

// cacheMiddleware sets caching headers
func cacheMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Set Cache-Control header
		w.Header().Set("Cache-Control", "public, max-age=86400") // Cache for 1 day
		next.ServeHTTP(w, r)
	})
}
