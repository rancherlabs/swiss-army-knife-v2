package health

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/rancherlabs/swiss-army-knife-v2/pkg/config"
	"github.com/rancherlabs/swiss-army-knife-v2/pkg/logging"
)

// VersionInfo represents the structure of version information.
type VersionInfo struct {
	Version   string `json:"version"`
	GitCommit string `json:"gitCommit"`
	BuildTime string `json:"buildTime"`
}

// logger is the global logger for the health package.
var logger = logging.SetupLogging(&config.CFG)

// Version information is set at build time.
var version = "MISSING VERSION INFO"

// GitCommit are set at build time.
var GitCommit = "MISSING GIT COMMIT"

// BuildTime are set at build time.
var BuildTime = "MISSING BUILD TIME"

// HealthzHandler returns a simple "ok" response.
func HealthzHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "ok")
	}
}

// VersionHandler returns version information as JSON.
func VersionHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logger.Info("VersionHandler")

		versionInfo := VersionInfo{
			Version:   version,
			GitCommit: GitCommit,
			BuildTime: BuildTime,
		}

		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(versionInfo); err != nil {
			logger.Error("Failed to encode version info to JSON", err)
			http.Error(w, "Failed to encode version info", http.StatusInternalServerError)
		}
	}
}
