lessc = node_modules/.bin/lessc
coffee = coffee
uglifyjs = uglifyjs

precedence = coffee/app.coffee coffee/lib coffee/models coffee/controllers coffee/views

prod: minify-css minify-js

compile-js:
	${coffee} --compile --join static/app.js ${precedence}

minify-js:
	#

compile-css:
	${lessc} less/master.less > static/master.css

minify-css:
	${lessc} -O3 --yui-compress less/master.less > static/master.css

dev-compile:
	supervisor --quiet -n exit --extensions 'coffee|less' --ignore 'static,node_modules' -x make run-dev

dev-server:
	supervisor --no-restart-on error --extensions 'go' --ignore 'static,node_modules' -x make run

run:
	go build
	./tetrus

run-dev: compile-css compile-js
