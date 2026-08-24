.PHONY: up down build logs backend-shell frontend-shell test test-docker lint clean

up: ## start backend + frontend (dev, with reload/HMR)
	docker compose up --build

down: ## stop and remove containers
	docker compose down

build: ## rebuild images without starting
	docker compose build

logs: ## tail logs from both services
	docker compose logs -f

backend-shell: ## shell into the running backend container
	docker compose exec backend sh

frontend-shell: ## shell into the running frontend container
	docker compose exec frontend sh

test: ## run backend + frontend test/lint suites locally (no docker)
	cd backend/martevi && pytest -q
	cd frontend && npm run lint && npx tsc -b --noEmit

test-docker: ## run backend + frontend test/lint suites inside the running containers (requires `make up` first)
	docker compose exec backend pytest -q
	docker compose exec frontend npm run lint
	docker compose exec frontend npx tsc -b --noEmit

clean: ## remove containers, volumes, and dangling images for this project
	docker compose down -v --remove-orphans
