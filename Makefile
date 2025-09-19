NVIM_EXEC ?= nvim

default: check test

.deps: .deps/mini.test

.deps/mini.test:
	@mkdir -p .deps
	git clone --filter=blob:none https://github.com/nvim-mini/mini.test $@

test: .deps
	${NVIM_EXEC} --headless --noplugin -u ./test/init.lua -c "lua MiniTest.run()"

check: check-fmt check-lua

check-fmt:
	stylua lua plugin test --color always --check

check-lua:
	luacheck lua plugin test

fmt:
	stylua lua plugin test

ci: check test


.PHONY: default fmt check check-fmt check-lua ci test
