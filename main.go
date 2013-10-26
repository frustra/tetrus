// Copyright 2013 Frustra Software. All rights reserved.
// Use of this source code is governed by the MIT license,
// which can be found in the LICENSE file.

package main

import (
	"log"

	"github.com/frustra/tetrus/server"
)

func main() {
	s, err := server.New()
	err = s.ListenAndServe()

	if err != nil {
		log.Fatalf("Failed to start server: %s\n", err)
	}
}
