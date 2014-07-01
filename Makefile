SHELL=/bin/bash

lessc = node_modules/.bin/lessc
coffee = node_modules/.bin/coffee
uglifyjs = node_modules/.bin/uglifyjs

precedence = coffee/app.coffee coffee/lib coffee/models coffee/controllers coffee/views
libs = polyfills,jquery-*,glmatrix-*,webrtc-*,batman,batman.jquery

production: install-dependencies assets compile-server
assets: css js manifest

compile-server:
	go get
	go build

install-dependencies:
	npm install

clean-manifest:
	rm -f manifest.json static/master-*.{js,css}

manifest: clean-manifest
	./manifest.sh

js: dev-js
	${uglifyjs} static/master.js --screw-ie8 --output static/master.min.js --comments --compress
	mv static/master.min.js static/master.js

css:
	${lessc} -O2 -x less/master.less > static/master.css


dev-assets: clean-manifest dev-css dev-js

dev-server: compile-server
	./tetrus -debug

dev-js:
	${coffee} --compile --join static/master.js ${precedence}
	cat lib/{${libs}}.js static/master.js > static/master.full.js
	mv static/master.full.js static/master.js

dev-css:
	${lessc} less/master.less > static/master.css

dev-watch-assets:
	supervisor --quiet -n exit --extensions 'coffee|less' --ignore 'static,node_modules' -x make dev-assets

dev-watch-server:
	supervisor --no-restart-on error --extensions 'go' --ignore 'static,node_modules' -x make dev-server

