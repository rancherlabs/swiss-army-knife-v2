package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"regexp"
	"strings"
	"syscall"
	"time"

	"github.com/sirupsen/logrus"

	"github.com/rancherlabs/swiss-army-knife-v2/pkg/config"
	"github.com/rancherlabs/swiss-army-knife-v2/pkg/logging"
	"github.com/rancherlabs/swiss-army-knife-v2/pkg/templates"
	"github.com/rancherlabs/swiss-army-knife-v2/pkg/version"
)

var (
	// Global logger variable
	logger *logrus.Logger
)

func main() {
	// Load configuration
	config.LoadConfiguration()
	logger = logging.SetupLogging(&config.CFG)

	// Graceful shutdown setup
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	done := make(chan struct{})

	server := startWebServer(config.CFG.Port)

	go func() {
		<-quit
		logger.Info("Shutting down server...")

		// Gracefully shutdown the server
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			logger.WithError(err).Error("Server shutdown failed")
		}
		close(done)
	}()

	<-done
	logger.Info("Server stopped")
}

func startWebServer(port int) *http.Server {
	logger.Info("Starting web server...")

	// Set up HTTP handlers
	http.HandleFunc("/", mainHandler)

	// Build the server address
	serverAddress := fmt.Sprintf(":%d", port)
	logger.WithField("port", serverAddress).Info("Serving Swiss-Army-Knife on HTTP port")

	// Define server with timeouts
	server := &http.Server{
		Addr:         serverAddress,
		ReadTimeout:  10 * time.Minute,
		WriteTimeout: 10 * time.Minute,
		IdleTimeout:  60 * time.Minute,
	}

	// Run the server in a separate goroutine
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("HTTP server failed to start: %v", err)
		}
	}()

	return server
}

// mainHandler handles requests to the root path and serves the HTML template
func mainHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	logger.WithFields(logrus.Fields{
		"method": r.Method,
		"url":    r.URL.String(),
	}).Info("Received request")

	// Extract additional data for the template
	ip := getIPAddress(r)
	namespace := os.Getenv("POD_NAMESPACE")
	nodeName := os.Getenv("NODE_NAME")
	nodeIP := os.Getenv("NODE_IP")

	// Prepare template data
	data := map[string]interface{}{
		"Hostname":  getHostname(),
		"GitCommit": version.GitCommit,
		"Host":      r.Host,
		"Headers":   r.Header,
		"IP":        ip,
		"Namespace": namespace,
		"NodeName":  nodeName,
		"NodeIP":    nodeIP,
		"Services":  getServices(),
	}

	// Render the HTML template
	output, err := templates.CompileTemplateFromMap(templates.HelloWorldTemplate, data)
	if err != nil {
		http.Error(w, "Error rendering template", http.StatusInternalServerError)
		logger.WithError(err).Error("Error rendering template")
		return
	}

	// Write the rendered template to the response
	w.Header().Set("Content-Type", "text/html")
	fmt.Fprint(w, output)

	// Log the request after processing
	responseTime := time.Since(start)
	logRequest(r, http.StatusOK, len(output), responseTime)
}

// getServices extracts Kubernetes services from environment variables
func getServices() map[string]string {
	services := make(map[string]string)

	for _, evar := range os.Environ() {
		parts := strings.Split(evar, "=")
		if len(parts) != 2 {
			continue
		}
		key, value := parts[0], parts[1]

		// Match Kubernetes service environment variables
		if matched, _ := regexp.MatchString("^.*_PORT$", key); matched {
			if linkMatched, _ := regexp.MatchString("^(tcp|udp)://.*", value); linkMatched {
				services[strings.TrimSuffix(key, "_PORT")] = value
			}
		}
	}

	return services
}

// getIPAddress extracts the client's IP address from the request
func getIPAddress(r *http.Request) string {
	// Check for forwarded headers
	if ip := r.Header.Get("X-Forwarded-For"); ip != "" {
		return ip
	}
	if ip := r.Header.Get("X-Real-IP"); ip != "" {
		return ip
	}

	// Fallback to RemoteAddr if no headers are present
	return r.RemoteAddr
}

// getHostname gets the hostname of the server
func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		logger.WithError(err).Error("Error getting hostname")
		return "unknown"
	}
	return hostname
}

// logRequest logs details about each HTTP request
func logRequest(r *http.Request, statusCode int, responseSize int, responseTime time.Duration) {
	remoteAddr := r.RemoteAddr
	usedHeader := "X-Forwarded-For"
	if ip := r.Header.Get("X-Forwarded-For"); ip != "" {
		remoteAddr = ip
	} else if ip := r.Header.Get("X-Real-IP"); ip != "" {
		remoteAddr = ip
		usedHeader = "X-Real-IP"
	}

	logger.WithFields(logrus.Fields{
		"remote_addr":   remoteAddr,
		"ip_source":     usedHeader,
		"method":        r.Method,
		"url":           r.URL.String(),
		"status":        statusCode,
		"response_size": responseSize,
		"response_time": responseTime.Seconds(),
		"user_agent":    r.UserAgent(),
		"referer":       r.Referer(),
		"host":          r.Host,
	}).Info("Processed request")
}
