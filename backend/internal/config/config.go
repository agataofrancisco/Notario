package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config contém todas as configurações da aplicação
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Google   GoogleConfig
	CORS     CORSConfig
	Logging  LoggingConfig
}

type ServerConfig struct {
	Port        string
	Environment string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

type JWTConfig struct {
	Secret                     string
	ExpirationHours            int
	RefreshTokenExpirationDays int
}

type GoogleConfig struct {
	ClientID       string
	ClientSecret   string
	RedirectURL    string
	CalendarAPIKey string
}

type CORSConfig struct {
	AllowedOrigins string
}

type LoggingConfig struct {
	Level string
}

// Load carrega as configurações das variáveis de ambiente
func Load() (*Config, error) {
	// Carregar .env se existir
	_ = godotenv.Load()

	config := &Config{
		Server: ServerConfig{
			Port:        getEnv("PORT", "8080"),
			Environment: getEnv("ENVIRONMENT", "development"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "notario"),
			Password: getEnv("DB_PASSWORD", ""),
			DBName:   getEnv("DB_NAME", "notario_db"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		JWT: JWTConfig{
			Secret:                     getEnv("JWT_SECRET", ""),
			ExpirationHours:            getEnvAsInt("JWT_EXPIRATION_HOURS", 1),
			RefreshTokenExpirationDays: getEnvAsInt("REFRESH_TOKEN_EXPIRATION_DAYS", 30),
		},
		Google: GoogleConfig{
			ClientID:       getEnv("GOOGLE_CLIENT_ID", ""),
			ClientSecret:   getEnv("GOOGLE_CLIENT_SECRET", ""),
			RedirectURL:    getEnv("GOOGLE_REDIRECT_URL", ""),
			CalendarAPIKey: getEnv("GOOGLE_CALENDAR_API_KEY", ""),
		},
		CORS: CORSConfig{
			AllowedOrigins: getEnv("ALLOWED_ORIGINS", "*"),
		},
		Logging: LoggingConfig{
			Level: getEnv("LOG_LEVEL", "info"),
		},
	}

	// Validar configurações obrigatórias
	if err := config.Validate(); err != nil {
		return nil, err
	}

	return config, nil
}

// Validate verifica se as configurações obrigatórias estão presentes
func (c *Config) Validate() error {
	if c.JWT.Secret == "" {
		return fmt.Errorf("JWT_SECRET é obrigatório")
	}

	if c.Google.ClientID == "" {
		return fmt.Errorf("GOOGLE_CLIENT_ID é obrigatório")
	}

	if c.Google.ClientSecret == "" {
		return fmt.Errorf("GOOGLE_CLIENT_SECRET é obrigatório")
	}

	if c.Database.Password == "" {
		return fmt.Errorf("DB_PASSWORD é obrigatório")
	}

	return nil
}

// GetDSN retorna a string de conexão PostgreSQL
func (c *Config) GetDSN() string {
	return fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		c.Database.Host,
		c.Database.Port,
		c.Database.User,
		c.Database.Password,
		c.Database.DBName,
		c.Database.SSLMode,
	)
}

// getEnv obtém variável de ambiente ou retorna valor padrão
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt obtém variável de ambiente como int ou retorna valor padrão
func getEnvAsInt(key string, defaultValue int) int {
	valueStr := getEnv(key, "")
	if value, err := strconv.Atoi(valueStr); err == nil {
		return value
	}
	return defaultValue
}
