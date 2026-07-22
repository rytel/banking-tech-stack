// Package topics serves the list of topics and their details.
package topics

import (
	"errors"

	"banking-tech-stack/backend/internal/models"
)

// ErrNotFound is returned by Get when no topic matches the given id.
var ErrNotFound = errors.New("topic not found")

// Service serves the static list of topics.
type Service struct {
	topics []models.Topic
}

// NewService creates a topics service backed by the built-in seed data.
func NewService() *Service {
	return &Service{topics: seed}
}

// List returns all topics.
func (s *Service) List() []models.Topic {
	return s.topics
}

// Get returns a single topic by id.
func (s *Service) Get(id string) (models.Topic, error) {
	for _, t := range s.topics {
		if t.ID == id {
			return t, nil
		}
	}
	return models.Topic{}, ErrNotFound
}
