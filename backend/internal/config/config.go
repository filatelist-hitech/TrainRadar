package config

import (
	"net"
	"os"
)

type Config struct {
	Host string
	Port string
}

func FromEnv() Config {
	return Config{
		Host: valueOrDefault("API_HOST", "127.0.0.1"),
		Port: valueOrDefault("API_PORT", "8080"),
	}
}

func (c Config) ListenAddress() string {
	return net.JoinHostPort(c.Host, c.Port)
}

func valueOrDefault(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
