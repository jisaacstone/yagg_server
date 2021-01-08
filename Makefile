fetest:
	mocha jstest/test*.js --require esm

betest:
	mix test && mix dialyzer

server:
	tsc && iex -S mix

built:
	./febuild && docker build . -t yagg
