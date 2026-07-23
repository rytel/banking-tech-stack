package handlers

import (
	"errors"
	"net/http"

	"banking-tech-stack/backend/internal/topics"
)

func listTopicsHandler(topicsSvc *topics.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		query := r.URL.Query().Get("q")
		writeJSON(w, http.StatusOK, topicsSvc.List(query))
	}
}

func getTopicHandler(topicsSvc *topics.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		topic, err := topicsSvc.Get(r.PathValue("id"))
		if err != nil {
			if errors.Is(err, topics.ErrNotFound) {
				writeError(w, http.StatusNotFound, "topic not found")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not load topic")
			return
		}

		writeJSON(w, http.StatusOK, topic)
	}
}
