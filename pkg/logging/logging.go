package logging

import (
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/sirupsen/logrus"
	"github.com/rancherlabs/swiss-army-knife-v2/pkg/config"
)

// logger is the global logger for the logging package.
var logger *logrus.Logger

// LogCallerInfo returns a log entry with the caller's filename and line number.
func LogCallerInfo() *logrus.Entry {
	_, filename, line, ok := runtime.Caller(1)
	if !ok {
		panic("Unable to get caller information")
	}
	filename = sanitizeLogField(filepath.Base(filename))

	cfg := config.CFG
	if cfg.Debug {
		return logger.WithField("filename", filename).WithField("line", line)
	}

	return logger.WithField("line", line)
}

// SetupLogging initializes the logger with the provided configuration.
func SetupLogging(cfg *config.AppConfig) *logrus.Logger {
	logger = logrus.New()
	logger.SetReportCaller(true)

	customFormatter := new(logrus.TextFormatter)
	customFormatter.TimestampFormat = "2006-01-02 15:04:05"
	customFormatter.FullTimestamp = true
	logger.SetFormatter(customFormatter)

	logger.SetOutput(os.Stderr)

	if cfg.Debug {
		logger.SetLevel(logrus.DebugLevel)
	} else {
		logger.SetLevel(logrus.InfoLevel)
	}

	return logger
}

// GetRelativePath logs the incoming HTTP request.
func GetRelativePath(filePath string) (string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	relPath, err := filepath.Rel(wd, filePath)
	if err != nil {
		return "", err
	}
	return relPath, nil
}

// sanitizeLogField replaces newline, carriage return, and tab characters with escape sequences.
func sanitizeLogField(input string) string {
	replacer := strings.NewReplacer(
		"\n", "\\n",
		"\r", "\\r",
		"\t", "\\t",
	)
	return replacer.Replace(input)
}

// LogRequest logs the incoming HTTP request.
func LogRequest(handler http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		remoteAddr := sanitizeLogField(r.RemoteAddr)
		method := sanitizeLogField(r.Method)
		uri := sanitizeLogField(r.URL.String())

		logger.WithFields(logrus.Fields{
			"remote_addr": remoteAddr,
			"method":      method,
			"url":         uri,
		}).Info("Received request")

		handler.ServeHTTP(w, r)
	}
}
