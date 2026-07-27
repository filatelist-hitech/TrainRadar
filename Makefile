SHELL := /bin/sh

.PHONY: setup compose-up validate-data lint test check

setup:
	command -v go >/dev/null
	command -v flutter >/dev/null
	command -v ruby >/dev/null
	command -v docker >/dev/null
	cd backend && go mod download
	cd mobile && flutter pub get

compose-up:
	docker compose up -d --wait --build

validate-data:
	ruby scripts/validate_reference_data.rb

lint:
	@unformatted="$$(find backend -type f -name '*.go' -exec gofmt -l {} +)"; \
	test -z "$$unformatted" || { echo "Unformatted Go files:"; echo "$$unformatted"; exit 1; }
	cd backend && go vet ./...
	cd mobile && flutter analyze
	ruby -c scripts/validate_reference_data.rb
	ruby -c scripts/validate_openapi.rb
	ruby scripts/validate_openapi.rb
	docker compose config --quiet

test:
	cd backend && go test ./...
	cd mobile && flutter test
	ruby test/validate_reference_data_test.rb
	ruby test/validate_openapi_test.rb

check: validate-data lint test
