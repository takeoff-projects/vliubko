package main

import (
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
)

type Pickerman struct {
	Name    string
	Status  string
	OrderID string
}

type PickermanList struct {
	PageTitle  string
	Pickermans []Pickerman
}

// func main() {
// 	tmpl := template.Must(template.ParseFiles("assets/index.html"))
// 	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
// 		data := PickermanList{
// 			PageTitle: "Takeoff Light",
// 			Pickermans: []Pickerman{
// 				{Name: "Picker 1", Status: "idle", OrderID: ""},
// 				{Name: "Picker 2", Status: "idle", OrderID: ""},
// 				{Name: "Picker 3", Status: "picking", OrderID: "123"},
// 			},
// 		}
// 		tmpl.Execute(w, data)
// 	})
// 	http.ListenAndServe(":8080", nil)
// }

func newRouter() *mux.Router {
	r := mux.NewRouter()
	r.HandleFunc("/hello", handler).Methods("GET")

	// Declare the static file directory and point it to the
	// directory we just made
	staticFileDirectory := http.Dir("./assets/")
	// Declare the handler, that routes requests to their respective filename.
	// The fileserver is wrapped in the `stripPrefix` method, because we want to
	// remove the "/assets/" prefix when looking for files.
	// For example, if we type "/assets/index.html" in our browser, the file server
	// will look for only "index.html" inside the directory declared above.
	// If we did not strip the prefix, the file server would look for
	// "./assets/assets/index.html", and yield an error
	staticFileHandler := http.StripPrefix("/assets/", http.FileServer(staticFileDirectory))
	// The "PathPrefix" method acts as a matcher, and matches all routes starting
	// with "/assets/", instead of the absolute route itself
	r.PathPrefix("/assets/").Handler(staticFileHandler).Methods("GET")
	return r
}

func main() {
	r := newRouter()
	err := http.ListenAndServe(":8080", r)
	if err != nil {
		fmt.Println(err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello World!")
}
