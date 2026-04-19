英文版说明：[README.md](./README.md)

<div align="center">
  <h1>MoonInk</h1>
  <p><strong>面向现有 Markdown 目录与 Obsidian 风格知识库的静态站点生成器。</strong></p>
  <p>
    <a href="https://github.com/Kozmosa/moonink/actions/workflows/publish-moonink-docs.yml"><img src="https://github.com/Kozmosa/moonink/actions/workflows/publish-moonink-docs.yml/badge.svg" alt="Docs publish status" /></a>
    <a href="./LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License: Apache 2.0" /></a>
  </p>
  <p>
    <a href="https://kozmosa.github.io/moonink/"><strong>官方文档与在线 Demo</strong></a>
    ·
    <a href="./README.md"><strong>English README</strong></a>
  </p>
</div>

MoonInk 可以直接把现有的 Markdown 目录生成静态网站，不要求你先迁移到 CMS 式内容系统。它适合 Obsidian 风格的知识库、WikiLink、frontmatter，以及以文档为中心的写作流程。

## 快速开始

### 直接在现有 Markdown 目录里使用 MoonInk

先在当前内容目录里生成配置：

```bash
moonink onboard
```

创建一个最小首页：

```md
---
title: Home
type: page
---

# Hello MoonInk

This site is built from an existing Markdown folder.
```

先检查，再构建：

```bash
moonink check
moonink build
```

启动本地预览：

```bash
moonink serve
```

`serve` 用于 native 预览；如果你是从源码运行，请使用下面的 native target 命令。

### 在本仓库中从源码运行

```bash
moon run src/cmd/main -- onboard
moon run src/cmd/main -- check
moon run src/cmd/main -- build
moon run src/cmd/main --target native -- serve
```

如果你要针对特定 vault 或 fixture 目录运行，可以附带 `--config <path>`。

## 文档与 Demo

完整文档位于 [kozmosa.github.io/moonink](https://kozmosa.github.io/moonink/)。这个站点本身也是一个用 MoonInk 构建出来的在线 Demo，因此你看到的文档站就是 MoonInk 的真实输出形态。

安装、首个站点、配置、链接、主题与 CLI 细节都应优先查看这里。

## 特性

- 直接从现有 Markdown 目录生成静态网站。
- 适配 Obsidian 风格目录结构与 WikiLink 工作流。
- 通过 frontmatter 与文件形态区分 page 和 article。
- 支持内置模板与项目级主题。
- 复制 `public/` 资源与内容树中的本地资源到输出目录。
- 输出静态 HTML，便于直接托管。
- 通过原生 `serve` 工作流进行本地预览。

## 仓库指南

项目结构：

```text
src/core       纯数据类型与共享逻辑
src/docflow    解析与渲染流水线
src/runtime    文件系统、配置加载与站点构建
src/cli        命令入口
src/cmd/main   二进制入口
docs/moonink   公开文档源目录，也是在线 Demo 站点的内容来源
```

常用开发命令：

```bash
moon check
moon test
moon fmt
moon info
```

如果你有意更新 snapshot 结果，使用 `moon test --update`。

## 贡献

欢迎提交 issue 和 pull request。若你修改了行为，请遵守 `src/` 下现有包边界，保持 fixture 具有代表性，并在完成改动后更新 `docs/agent-working/worklog/` 中的工作记录。

## 许可证

MoonInk 采用 [Apache License 2.0](./LICENSE) 许可证。
