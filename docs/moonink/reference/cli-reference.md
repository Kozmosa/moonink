---
title: CLI Reference
summary: MoonInk 当前公开的命令面包括 help、onboard、build、check、serve，以及它们稳定可用的 flags。
---

这一页只列当前稳定可写进用户文档的命令与参数。

## 命令与 flags

| Command | Flags | 说明 |
| --- | --- | --- |
| `help` | 无 | 显示 CLI 入口 |
| `onboard` | 无 | 在当前目录写 `moonink.json`；已存在时中止 |
| `build` | `--config`, `--output` | 生成静态输出 |
| `check` | `--config`, `--output` | validation-only 预检 |
| `serve` | `--config`, `--output`, `--host`, `--port` | build 后启动本地 preview，且仅限 native |

## 默认值

| Flag | 默认值 |
| --- | --- |
| `--config` | `moonink.json` |
| `--output` | 不覆盖 config；通常是 `dist` |
| `--host` | `127.0.0.1` |
| `--port` | `3000` |

## 常见调用

binary 形式：

```bash
moonink build --config docs/moonink/moonink.json
moonink check --config docs/moonink/moonink.json
moonink serve --config docs/moonink/moonink.json --host 127.0.0.1 --port 3000
```

source-run 形式：

```bash
moon run src/cmd/main -- build --config docs/moonink/moonink.json
moon run src/cmd/main -- check --config docs/moonink/moonink.json
moon run src/cmd/main --target native -- serve --config docs/moonink/moonink.json
```

## 返回边界

- `build`：成功返回 `0`；如果只是出现构建诊断，也仍然可能返回成功
- `check`：warning-only 返回 `0`，error 返回 `1`
- `serve`：先 build，再进入 preview；真实 preview 是 `native-only`

## 相关页面

- [[cli]]
- [[check-and-serve]]
