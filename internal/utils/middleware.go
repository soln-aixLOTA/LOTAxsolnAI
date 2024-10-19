package utils

import (
    "time"

    "github.com/gin-gonic/gin"
    log "github.com/sirupsen/logrus"
)

// LoggerMiddleware logs each incoming HTTP request.
func LoggerMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        startTime := time.Now()
        c.Next()
        duration := time.Since(startTime)

        log.WithFields(log.Fields{
            "method":   c.Request.Method,
            "path":     c.Request.URL.Path,
            "status":   c.Writer.Status(),
            "duration": duration,
            "clientIP": c.ClientIP(),
        }).Info("Handled request")
    }
}
