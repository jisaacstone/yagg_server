fetest:
	mocha jstest/test*.js --require esm

betest:
	mix test && mix dialyzer

server:
	./node_modules/.bin/tsc && iex -S mix

built:
	./febuild && docker build . -t yagg
