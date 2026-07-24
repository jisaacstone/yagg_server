fetest:
	mocha jstest/test*.js --require esm

typetest:
	./node_modules/.bin/tsc -p tsconfig.strict.json

betest:
	mix test && mix dialyzer

server:
	./node_modules/.bin/tsc && iex -S mix

built:
	./febuild && docker build . -t yagg
