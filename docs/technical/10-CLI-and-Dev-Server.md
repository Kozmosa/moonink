# 10 CLI And Dev Server

## 1. CLI Surface In V1

- `moonink new`
- `moonink build`
- `moonink serve`

## 2. Command Responsibilities

### `new`

Create a starter project with a default configuration, sample content, and official theme assets.

### `build`

Run the full static generation pipeline and emit the final site output.

### `serve`

Run a local development server for previewing the generated site. V1 may begin with simple rebuild-and-refresh behavior rather than sophisticated hot reload.

## 3. CLI Output Style

CLI messages should be concise, calm, and diagnostic-friendly. Success, warning, and failure output must help authors locate content issues quickly.

## 4. Evolution Path

Later commands may include `check`, `deploy`, `doctor`, or theme/plugin-related tooling once the core surface is stable.
