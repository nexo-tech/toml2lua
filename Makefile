.PHONY: toml_test

shell:
	nix shell nixpkgs#luarocks nixpkgs#lua nixpkgs#go
	
toml_test_install:
	GOBIN=$$(pwd) go install github.com/toml-lang/toml-test/cmd/toml-test@latest

toml_test:
	@./toml-test ./toml_test/decoder.lua 2>&1 | perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g' > results.txt
	@echo "Output saved to results.txt"