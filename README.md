tetrus
======

tetrus is a cooperative, peer to peer [tile-matching](http://en.wikipedia.org/wiki/Tile-matching_video_game) browser game.

It uses:

  - [batman.js][] for managing application and view state
  - [WebRTC][] for initiating the p2p data connection
  - [WebGL][] for rendering
  - [WebSockets][] for client session control
  - [Go][] for the server-side

[batman.js]: http://batmanjs.org/
[WebRTC]: http://www.webrtc.org/
[WebGL]: http://en.wikipedia.org/wiki/WebGL
[WebSockets]: http://en.wikipedia.org/wiki/WebSocket
[Go]: http://golang.org/

### play it at [tetrus.frustra.org](tetrus.frustra.org)

## Developing

First, make sure you have Go and node.js installed. Then, grab the code by running `go get github.com/frustra/tetrus`, which will place the repository into your $GOPATH.

To compile the assets, switch to the tetrus directory, run `npm install`, then run one of these tasks:

  - `make assets` compile minified, fingerprinted versions of the CSS and JS
  - `make dev-assets` compile unminified versions of the CSS and JS
  - `make dev-watch-assets` compiles the unminified CSS and JS on every change

Then, start up the server with one of these tasks:

  - `make server` compile the server
  - `make dev-server` compile and run the server in debug mode
  - `make dev-watch-server` compiles and runs the server on every change

