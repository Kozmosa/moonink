---
title: 安装 MoonInk
summary: MoonInk 同时支持 binary install 和 source-run，两条路径都能进入同一套 CLI 工作流。
---

这一页只解决一个问题：怎样把 MoonInk 跑起来。装好之后，继续看 [[first-site]]。

## 路径一：使用 binary

MoonInk 的 binary 分发入口是 GitHub Releases：`github.com/Kozmosa/moonink`。

推荐流程：

1. 打开 Releases 页面。
2. 下载与你的平台匹配的压缩包或可执行文件。
3. 解压后把 `moonink` 放进你的 `PATH`。
4. 运行 `moonink help` 确认命令可用。

```bash
moonink help
```

如果你准备在本地预览站点，后面运行 `serve` 时请使用 native 环境；`serve` 是 `native-only`。

## 路径二：从源码运行

如果你正在仓库里开发、验证或试用 MoonInk，可以直接 source-run。

前置条件：

- 已安装 MoonBit toolchain
- 已 clone MoonInk 仓库

常用起步命令：

```bash
moon run src/cmd/main -- help
```

```bash
moon run src/cmd/main -- build --config docs/moonink/moonink.json
```

需要本地预览时，使用 native target：

```bash
moon run src/cmd/main --target native -- serve --config docs/moonink/moonink.json
```

## 选哪条路径

- 想直接使用 MoonInk：优先 binary install。
- 想边看仓库边验证行为：优先 source-run。

无论你走哪条路径，CLI surface 都一样。命令面总览见 [[cli]]，参数细节见 [[cli-reference]]。

## 装好之后做什么

- 新建一个站点：[[first-site]]
- 现有 Vault 接入：[Obsidian Vault 指南](../guide/obsidian-vault.md)
- 先理解 `check` 的角色：[[check-and-serve]]
