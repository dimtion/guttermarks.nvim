check: check-fmt check-lua

check-fmt:
	stylua lua plugin --color always --check

check-lua:
	luacheck lua plugin

fmt:
	stylua lua plugin

ci: check


.PHONY: fmt check check-fmt check-lua ci
