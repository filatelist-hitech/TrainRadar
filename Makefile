SHELL := /bin/sh

.PHONY: setup compose-up validate-data schema-check format-check lint test build brand-assets \
	docs-sync docs-check check-staged check-full install-hooks ready check

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

schema-check: validate-data
	ruby scripts/validate_openapi.rb
	docker compose config --quiet

format-check:
	@unformatted="$$(find backend -type f -name '*.go' -exec gofmt -l {} +)"; \
	test -z "$$unformatted" || { echo "Unformatted Go files:"; echo "$$unformatted"; exit 1; }
	cd mobile && dart format --output=none --set-exit-if-changed lib test

lint:
	cd backend && go vet ./...
	cd mobile && flutter analyze
	ruby -c scripts/validate_reference_data.rb
	ruby -c scripts/verify_corridor_sources.rb
	ruby -c scripts/validate_openapi.rb
	ruby -c scripts/docs_gate.rb

test:
	cd backend && go test ./...
	cd mobile && flutter test
	ruby -e 'Dir["test/**/*_test.rb"].sort.each { |file| load file }'

build:
	cd backend && mkdir -p bin && go build -o bin/trainradar-api ./cmd/api
	cd mobile && flutter build apk --debug

brand-assets:
	ruby scripts/docs_gate.rb brand-assets

docs-sync:
	ruby scripts/docs_gate.rb sync

docs-check:
	ruby scripts/docs_gate.rb check

check-staged:
	ruby scripts/docs_gate.rb pre-commit

check-full: format-check lint test build schema-check brand-assets docs-check

install-hooks:
	ruby scripts/docs_gate.rb install-hooks

ready: check-full

check: format-check lint test schema-check brand-assets docs-check
