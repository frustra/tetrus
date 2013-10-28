// Copyright 2013 Frustra Software. All rights reserved.
// Use of this source code is governed by the MIT license,
// which can be found in the LICENSE file.

package server

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
	"text/template"
)

func (s *Server) LoadManifest() {
	template, err := template.ParseFiles(s.Root + "/html/index.html")
	if err != nil {
		log.Fatalf("Error loading html/index.html: %s", err)
	}

	buffer := new(bytes.Buffer)

	file, err := ioutil.ReadFile(s.Root + "/manifest.json")
	if err != nil {
		log.Println("Missing asset manifest, assuming dev mode")
		template.Execute(buffer, map[string]string{"js": "master.js", "css": "master.css"})
	} else {
		manifest := make(map[string]string)
		json.Unmarshal(file, &manifest)
		template.Execute(buffer, map[string]string{"js": manifest["master.js"], "css": manifest["master.css"]})
	}
	s.LayoutBuffer = buffer.Bytes()
}

func (s *Server) ServeLayout(w http.ResponseWriter, r *http.Request) {
	w.Write(s.LayoutBuffer)
}
