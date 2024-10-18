package cybersecurity_ai

import (
    "errors"
    "strings"
    "sync"

    "ai-platform/internal/utils"

    log "github.com/sirupsen/logrus"
)

// Threat represents a cybersecurity threat.
type Threat struct {
    ID          int
    Description string
    Severity    string
}

// ThreatIntelligence gathers and analyzes threat data.
type ThreatIntelligence struct {
    logger  *log.Entry
    threats map[int]Threat
    mu      sync.RWMutex
    nextID  int
}

// NewThreatIntelligence initializes a new ThreatIntelligence system.
func NewThreatIntelligence() *ThreatIntelligence {
    logger := utils.GetLogger().WithField("module", "cybersecurity_ai_threat_intelligence")
    return &ThreatIntelligence{
        logger:  logger,
        threats: make(map[int]Threat),
        nextID:  1,
    }
}

// AddThreat adds a new threat to the intelligence system.
func (ti *ThreatIntelligence) AddThreat(description, severity string) {
    ti.mu.Lock()
    defer ti.mu.Unlock()
    ti.threats[ti.nextID] = Threat{
        ID:          ti.nextID,
        Description: description,
        Severity:    severity,
    }
    ti.logger.Infof("Added threat: ID %d, Severity %s", ti.nextID, severity)
    ti.nextID++
}

// AnalyzeThreat analyzes a given description to identify potential threats.
// Placeholder: Integrate with natural language processing or threat databases.
func (ti *ThreatIntelligence) AnalyzeThreat(description string) (Threat, error) {
    ti.mu.RLock()
    defer ti.mu.RUnlock()

    // Placeholder logic: Simple keyword-based threat identification
    if len(description) == 0 {
        ti.logger.Warn("Empty description provided for threat analysis.")
        return Threat{}, errors.New("empty description")
    }

    var severity string
    if containsKeyword(description, "malware") || containsKeyword(description, "virus") {
        severity = "High"
    } else if containsKeyword(description, "phishing") || containsKeyword(description, "spam") {
        severity = "Medium"
    } else {
        severity = "Low"
    }

    threat := Threat{
        ID:          ti.nextID,
        Description: description,
        Severity:    severity,
    }

    ti.logger.Infof("Analyzed threat: %+v", threat)
    return threat, nil
}

// Helper function to check for keywords in the description.
func containsKeyword(description, keyword string) bool {
    return strings.Contains(strings.ToLower(description), strings.ToLower(keyword))
}
