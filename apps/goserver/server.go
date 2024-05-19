package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

var startedAt = time.Now()

func main() {
	http.HandleFunc("/", Hello)
	http.HandleFunc("/healthz", Healthz)
	http.HandleFunc("/secrets", Secret)
	log.Fatal(http.ListenAndServe(":8000", nil))
}

func Hello(w http.ResponseWriter, r *http.Request) {
	name := os.Getenv("NAME")
	age := os.Getenv("AGE")
	if name == "" {
		name = "Guest"
	}
	if age == "" {
		age = "unknown"
	}
	fmt.Fprintf(w, "Hello, I'm %s. I'm %s years old.", name, age)
}

func Secret(w http.ResponseWriter, r *http.Request) {
	user := os.Getenv("USER")
	password := os.Getenv("PASSWORD")
	if user == "" || password == "" {
		http.Error(w, "User or password not set", http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, "user: %s, password: %s", user, password)
}

func Healthz(w http.ResponseWriter, r *http.Request) {
	duration := time.Since(startedAt)
	if duration.Seconds() < 10 {
		w.WriteHeader(http.StatusInternalServerError)
		if _, err := w.Write([]byte(fmt.Sprintf("Duration: %v", duration.Seconds()))); err != nil {
			log.Printf("Error writing response: %v", err)
		}
	} else {
		w.WriteHeader(http.StatusOK)
		if _, err := w.Write([]byte("ok")); err != nil {
			log.Printf("Error writing response: %v", err)
		}
	}
}
