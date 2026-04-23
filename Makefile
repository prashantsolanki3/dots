# dots — Makefile
#
# Cross-platform entrypoints. After the macOS hygiene fixes (base + docker
# roles gated on os_family == Debian, claude_code npm install no-sudo on
# Darwin), dev.yml runs on macOS and Linux identically without special flags.
#
# Usage:
#   make check              # dry-run (safe; shows diff)
#   make dev                # apply dev.yml to localhost
#   make scaffold-wiki REPO=/abs/path    # scaffold LLM-wiki into target repo

ANSIBLE_COMMON = \
	ansible-playbook \
	--connection=local \
	-i "localhost," \
	-e ansible_python_interpreter=/usr/bin/python3

.PHONY: check dev scaffold-wiki lint help

help:
	@echo "dots — make targets"
	@echo "  check                 Dry-run dev.yml (no changes applied)"
	@echo "  dev                   Apply dev.yml to localhost"
	@echo "  scaffold-wiki REPO=…  Scaffold LLM-wiki structure into REPO (absolute path)"
	@echo "  lint                  Run ansible-lint"

check:
	$(ANSIBLE_COMMON) dev.yml --check --diff

dev:
	$(ANSIBLE_COMMON) dev.yml

scaffold-wiki:
	@if [ -z "$(REPO)" ]; then \
		echo "error: REPO=<absolute-path> required"; \
		echo "example: make scaffold-wiki REPO=/Users/you/Playground/some-project"; \
		exit 1; \
	fi
	$(ANSIBLE_COMMON) scaffold-wiki.yml -e "wiki_target=$(REPO)"

lint:
	ansible-lint --show-relpath
