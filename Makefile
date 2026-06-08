.PHONY: lint

lint:
	terraform fmt && \
	cd modules/landscape-client && \
	terraform init -backend=false && \
	terraform fmt
