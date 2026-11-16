package progress

import (
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"
)

type TokenVerifier interface {
	Verify(ctx context.Context, rawToken string) (string, error)
}

type googleVerifier struct {
	audience string
	client   *http.Client
	mu       sync.Mutex
	keys     map[string]*rsa.PublicKey
	expires  time.Time
}

func NewGoogleVerifier(audience string) TokenVerifier {
	return &googleVerifier{audience: audience, client: &http.Client{Timeout: 5 * time.Second}}
}

func (v *googleVerifier) Verify(ctx context.Context, rawToken string) (string, error) {
	parts := strings.Split(rawToken, ".")
	if len(parts) != 3 {
		return "", fmt.Errorf("malformed JWT")
	}
	var header struct {
		Algorithm string `json:"alg"`
		KeyID     string `json:"kid"`
	}
	var claims struct {
		Issuer   string `json:"iss"`
		Audience any    `json:"aud"`
		Subject  string `json:"sub"`
		Expiry   int64  `json:"exp"`
	}
	if err := decodeJWT(parts[0], &header); err != nil {
		return "", err
	}
	if err := decodeJWT(parts[1], &claims); err != nil {
		return "", err
	}
	if header.Algorithm != "RS256" || header.KeyID == "" {
		return "", fmt.Errorf("unsupported JWT header")
	}
	if claims.Issuer != "https://accounts.google.com" && claims.Issuer != "accounts.google.com" {
		return "", fmt.Errorf("invalid issuer")
	}
	if claims.Subject == "" || claims.Expiry <= time.Now().Unix() || !matchesAudience(claims.Audience, v.audience) {
		return "", fmt.Errorf("invalid token claims")
	}
	key, err := v.key(ctx, header.KeyID)
	if err != nil {
		return "", err
	}
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return "", err
	}
	hash := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	if err := rsa.VerifyPKCS1v15(key, crypto.SHA256, hash[:], signature); err != nil {
		return "", fmt.Errorf("invalid signature")
	}
	return claims.Subject, nil
}

func decodeJWT(part string, destination any) error {
	raw, err := base64.RawURLEncoding.DecodeString(part)
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, destination)
}
func matchesAudience(audience any, expected string) bool {
	switch value := audience.(type) {
	case string:
		return value == expected
	case []any:
		for _, item := range value {
			if text, ok := item.(string); ok && text == expected {
				return true
			}
		}
	}
	return false
}

func (v *googleVerifier) key(ctx context.Context, keyID string) (*rsa.PublicKey, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	if time.Now().After(v.expires) || v.keys[keyID] == nil {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://www.googleapis.com/oauth2/v1/certs", nil)
		if err != nil {
			return nil, err
		}
		response, err := v.client.Do(req)
		if err != nil {
			return nil, err
		}
		defer response.Body.Close()
		if response.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("Google certificates status %d", response.StatusCode)
		}
		body, err := io.ReadAll(io.LimitReader(response.Body, 1<<20))
		if err != nil {
			return nil, err
		}
		var certificates map[string]string
		if err := json.Unmarshal(body, &certificates); err != nil {
			return nil, err
		}
		keys := make(map[string]*rsa.PublicKey, len(certificates))
		for id, pemText := range certificates {
			block, _ := pem.Decode([]byte(pemText))
			if block == nil {
				continue
			}
			certificate, err := x509.ParseCertificate(block.Bytes)
			if err != nil {
				continue
			}
			if key, ok := certificate.PublicKey.(*rsa.PublicKey); ok {
				keys[id] = key
			}
		}
		if len(keys) == 0 {
			return nil, fmt.Errorf("no Google verification keys")
		}
		v.keys, v.expires = keys, time.Now().Add(time.Hour)
	}
	key := v.keys[keyID]
	if key == nil {
		return nil, fmt.Errorf("unknown Google key id")
	}
	return key, nil
}
