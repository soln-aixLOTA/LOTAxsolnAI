package unit

import (
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/soln-aixLOTA/LOTAxsolnAI/internal/ai_chatbot"
    "github.com/soln-aixLOTA/LOTAxsolnAI/internal/config"
)

func TestGenerateText(t *testing.T) {
    // Mock server
    handler := func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        w.Write([]byte(`{
            "generated_text": "There are 3 'r's in 'strawberry'."
        }`))
    }
    server := httptest.NewServer(http.HandlerFunc(handler))
    defer server.Close()

    modelCfg := config.ModelConfig{
        InferenceURL: server.URL,
        APIKey:       "test-api-key",
    }

    aiClient := ai_chatbot.NewAIClient(modelCfg)

    prompt := "How many 'r's are in the word 'strawberry'?"
    response, err := aiClient.GenerateText(prompt)
    if err != nil {
        t.Fatalf("Expected no error, got %v", err)
    }

    expected := "There are 3 'r's in 'strawberry'."
    if response != expected {
        t.Errorf("Expected '%s', got '%s'", expected, response)
    }
}
