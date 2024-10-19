package utils

import (
    "os"

    log "github.com/sirupsen/logrus"
)

// InitLogger sets up the logger with desired configurations.
func InitLogger() {
    // Set the output to stdout
    log.SetOutput(os.Stdout)

    // Set the log level (can be made configurable)
    log.SetLevel(log.InfoLevel)

    // Set the formatter to JSON for better integration with log management systems
    log.SetFormatter(&log.JSONFormatter{
        TimestampFormat: "2006-01-02T15:04:05Z07:00",
    })
}

// GetLogger returns a new log entry with standardized fields.
func GetLogger() *log.Entry {
    return log.WithFields(log.Fields{
        "app": "LOTAxsolnAI",
    })
}
