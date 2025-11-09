NVIM_EXEC ?= nvim
TIMEOUT ?= timeout

default: check test

.deps: .deps/mini.test

.deps/mini.test:
	@mkdir -p .deps
	git clone --filter=blob:none https://github.com/nvim-mini/mini.test $@

test: .deps
	${NVIM_EXEC} --headless --noplugin -u ./test/init.lua -c "lua MiniTest.run()"

bench: .deps
	@${TIMEOUT} 120 ${NVIM_EXEC} --headless --noplugin -u ./test/bench/init.lua -c "lua MiniTest.run()"

check: check-fmt check-lua

check-fmt:
	stylua lua plugin test --color always --check

check-lua:
	luacheck lua plugin test

fmt:
	stylua lua plugin test

.PHONY: default fmt check check-fmt check-lua ci test bench
