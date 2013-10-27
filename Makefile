lessc = node_modules/.bin/lessc
coffee = node_modules/.bin/coffee
uglifyjs = node_modules/.bin/uglifyjs

precedence = coffee/app.coffee coffee/lib coffee/models coffee/controllers coffee/views

production: install compile-css compile-js manifest compile-server

install:
	npm install

manifest:
	rm -f static/master.*.js
	rm -f static/master.*.css
	./manifest.sh

compile-js: dev-compile-js
	${uglifyjs} static/master.js --screw-ie8 --output static/master.min.js --comments --compress
	mv static/master.min.js static/master.js

compile-css:
	${lessc} -O3 --yui-compress less/master.less > static/master.css

compile-server:
	go build

dev-compile-js:
	${coffee} --compile --join static/master.js ${precedence}

dev-compile-css:
	${lessc} less/master.less > static/master.css

dev-compile:
	supervisor --quiet -n exit --extensions 'coffee|less' --ignore 'static,node_modules' -x make dev-compile-assets

dev-server:
	supervisor --no-restart-on error --extensions 'go' --ignore 'static,node_modules' -x make dev-run

dev-run: compile-server
	./tetrus -debug

dev-compile-assets: dev-compile-css dev-compile-js

