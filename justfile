# Maintain the local Career Ops installation and its optional web app.

default:
    @just --list

install:
    npm ci --ignore-scripts --include=dev
    npm --prefix web ci --ignore-scripts --include=dev

browser:
    node node_modules/playwright/cli.js install chromium

lint:
    npm run lint

test:
    node test-all.mjs

test-web:
    npm --prefix web test

test-browser:
    npm --prefix web run test:browser

check-web:
    npm --prefix web run typecheck
    npm --prefix web run build

test-dashboard:
    cd dashboard && go test ./...
    cd dashboard && go build -o career-dashboard .

audit:
    npm audit
    npm --prefix web audit

audit-dashboard:
    cd dashboard && go run golang.org/x/vuln/cmd/govulncheck@latest ./...

doctor:
    node doctor.mjs --cli codex --json
