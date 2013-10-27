// Copyright 2013 Frustra Software. All rights reserved.
// Use of this source code is governed by the MIT license,
// which can be found in the LICENSE file.

package main

import (
	"flag"
	"log"

	"github.com/frustra/tetrus/server"
)

var port = flag.Int("port", 8080, "which port to listen on")
var debug = flag.Bool("debug", false, "enables verbose logging")

func main() {
	flag.Parse()
	s, err := server.New(*port, *debug)
	err = s.ListenAndServe()

	if err != nil {
		log.Fatalf("Failed to start server: %s\n", err)
	}
}
