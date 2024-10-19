package utils

import (
    "fmt"
    "runtime/debug"
    "strings"

    log "github.com/sirupsen/logrus"
)

// RecoverPanic recovers from a panic and logs the stack trace.
func RecoverPanic() {
    if r := recover(); r != nil {
        log.Errorf("Panic recovered: %v", r)
        log.Errorf("Stack Trace: %s", debug.Stack())
    }
}

// WrapError formats an error with additional context.
func WrapError(context string, err error) error {
    if err != nil {
        return fmt.Errorf("%s: %w", context, err)
    }
    return nil
}

// ValidateString checks if a string is non-empty.
func ValidateString(fieldName, value string) error {
    if strings.TrimSpace(value) == "" {
        return fmt.Errorf("validation failed: %s cannot be empty", fieldName)
    }
    return nil
}
