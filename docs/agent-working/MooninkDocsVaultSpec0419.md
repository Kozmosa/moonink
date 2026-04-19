# MoonInk 用户文档 Vault Spec 0419

_Date_: 2026-04-19

## Goal

为 `docs/moonink/` 定义一套独立、自洽、可直接被 MoonInk 编译的用户文档 vault 规格。该文档站面向首次上手用户，使用“简体中文主体 + English nouns”的表达方式，采用 MoonInk 兼容的 Markdown 组织形式，并在不依赖仓库内现有文档页面的前提下，完整覆盖当前已经 shipped 的用户功能。

这份 spec 只定义文档产品边界、信息架构、页面清单、写作规则、示例策略与验收标准，不直接开始撰写 `docs/moonink/` 的实际页面内容。

## Audience

- primary audience: 首次上手 MoonInk 的用户；
- secondary audience: 需要把普通 Markdown folder 或 Obsidian vault 接入 MoonInk 的作者；
- not the audience: MoonInk contributor、架构维护者、主题系统内部实现读者。

## Confirmed Product Decisions

- 文档只覆盖当前 shipped features，不写 roadmap、planned behavior 或未来 contract。
- `check` 是 first-class command，必须在 Quick Start、Guide、Reference、FAQ 中都获得明确位置。
- `serve` 必须在所有相关页面中明确标注为 `native-only`。
- 安装章节需要同时覆盖“使用 binary”和“从源码运行/构建”两条路径。
- 首版不写 hosting / deployment 文档。
- Obsidian vault workflow 与普通 Markdown folder workflow 并列，而不是隐藏在 appendix。
- 文档主路径只写当前稳定、推荐的用法。
- Theme V2 直接定义为推荐默认主题路径。
- 文档中的字段说明只写当前可稳定对外表达的字段。
- `docs/moonink/` 本身应该是一个 demo showcase，主动展示现有能力。
- `docs/moonink/` 首版使用 built-in default theme，不引入自定义项目主题。
- 页面标题偏中文，命令、字段名、文件名、config key、frontmatter key 保留英文原词。
- 文风偏 product docs，而不是 contributor notes 或 architecture notes。
- `docs/moonink/` 不能依赖或链接仓库里现有文档；若需要复用内容，只能重写并拷贝进新 vault。
- 最低完成标准是文档 vault 至少能够成功 `build`。

## Hard Constraints

### 1. Standalone Vault

`docs/moonink/` 必须是独立内容根，不得通过链接、include、引用说明等方式依赖：

- `docs/technical/`
- `docs/zh/technical/`
- `README.mbt.md`
- `docs/agent-working/`
- 任何 `docs/superpowers/` 页面

允许把这些文件中的事实内容重写后迁移进 `docs/moonink/`，但最终站点不能把它们当作上游依赖。

### 2. Shipped-Only Truth Boundary

只有在代码和 fixture 中已经可验证的能力才能进入文档主路径。对用户文档的事实判断以当前实现为准，而不是以旧设计文档、旧 README 文案或希望中的产品方向为准。

### 3. Build-Compatible Markdown

`docs/moonink/` 的内容结构必须兼容当前 MoonInk 构建器：

- 使用标准 Markdown 文件；
- 需要时使用 frontmatter；
- 内部链接优先采用 MoonInk 当前支持的 `[[WikiLink]]` / Markdown link 形式；
- 必须避免引入当前实现未证明支持的特殊 Markdown contract。

## Authoritative Feature Boundary For The Docs

本节定义 `docs/moonink/` 可以对外陈述的事实边界。

### 1. CLI Surface That May Be Documented

当前真实命令：

- `moonink help`
- `moonink onboard`
- `moonink build`
- `moonink check`
- `moonink serve`

当前真实参数：

- `build`: `--config`, `--output`
- `check`: `--config`, `--output`
- `serve`: `--config`, `--output`, `--host`, `--port`

当前真实行为：

- `onboard` 不接收 flags 或 positional arguments，会在当前目录写入 `moonink.json`，若已存在则中止；
- `build` 负责静态构建；
- `check` 负责 validation-only 预检，warning-only 返回 `0`，blocking error 返回 `1`；
- `serve` 会先 build，再委托 native preview backend 启动本地预览；
- `serve` 的真实 HTTP preview 只在 native target 上可用，非 native target 出现 “only available on native targets” 属于预期行为。

### 2. Config Surface That May Be Documented

`moonink.json` 当前可稳定写入用户文档的字段：

- `site_name`
- `site_url`
- `content_dir`
- `output_dir`
- `exclude`
- `route_style`
- `theme`
- `theme_config`

兼容但不作为首版推荐主路径展开的字段：

- `template_file`

说明：`template_file` 仍是 shipped feature，但由于本轮文档主路径明确推荐 Theme V2，因此不作为首页、Quick Start、主 Guide 的默认路线，只允许在 Theme / Compatibility 边界说明中简短点到。

### 3. Frontmatter Surface That May Be Documented

适合内容作者主路径文档的字段：

- `title`
- `description`
- `type`
- `date`
- `updated`
- `summary`
- `series`
- `cover`
- `author`
- `column`
- `tags`
- `draft`

需要降级为 “Theme author / advanced override” 语境处理的字段：

- `layout`

原因：`layout` 虽然已被解析，但它依赖 active theme manifest 中的 `page_overrides` allowlist。对使用 built-in default theme 的首次上手用户来说，`layout` 不是一个应被主路径推荐的常规内容字段。

明确不纳入首版用户 frontmatter 文档的字段：

- `featured`
- `pinned`
- `search`
- `toc`
- `nav_title`
- `nav_hidden`

原因：这些字段要么当前没有稳定解析/验证 contract，要么只存在于内部 / `extra` 路径，不适合在 shipped-only 的首次用户文档中写成正式支持项。

### 4. Content, Linking, And Asset Behavior That May Be Documented

当前可以明确写入的能力：

- `.md` 默认按 article 处理；
- `.html` 按 page 处理；
- `.md` + `type: page` 可转为 page；
- 根 `index.*` 为首页；若无根 `index.*`，根 `README.md` 会被提升为首页；
- 支持普通 Markdown 内链；
- 支持 `[[WikiLink]]`；
- 支持 `[[target|label]]`；
- 支持资源型 `[[file.png]]`；
- 支持 `![[image.png]]` embed；
- 内容树里的非 Markdown / HTML 文件会作为 passthrough assets 复制到输出目录；
- 根 `public/` 会整体复制到输出目录；
- Theme assets 会复制到 `dist/assets/`。

### 5. Theme Surface That May Be Documented

Theme V2 当前可对外陈述的 manifest key：

- `name`
- `layouts`
- `tokens`
- `page_overrides`
- `slots`

当前可明确写入的 Theme V2 目录概念：

- `theme/theme.json`
- `theme/layouts/`
- `theme/partials/`
- `theme/assets/`

## Explicit Non-Goals For The First Docs Vault

以下内容不进入首版 `docs/moonink/`：

- hosting / deployment 教程；
- public search page 的用户手册；
- RSS / Open Graph / canonical / social metadata 说明；
- 未稳定的 metadata 行为 contract；
- 以 legacy `template_file` / `theme/layout.html` 为中心的老路径教程；
- contributor-oriented architecture deep dive；
- 对未 shipped 特性的承诺式描述。

## Reality Conflicts That The Spec Must Preserve

### 1. Binary Install Path Uses GitHub Releases

用户已经确认 binary install 的分发来源为 GitHub Releases，项目地址为 `github.com/Kozmosa/moonink`。

因此首版文档可以把 binary install 作为正式支持路径写入安装章节，但要遵守两个约束：

- 安装页可以引用 GitHub Releases 作为发布渠道；
- 具体下载文件名、平台矩阵、安装命令和校验步骤，必须以实际 release 页面中的可见 artifact 为准，不能在未检查 release 产物命名之前提前写死。

### 2. `layout` Is Not A Beginner-Default Field

虽然用户希望把行为字段写成 “已支持并推荐”，但当前代码现实要求文档更严格：

- `draft` 可以作为常规内容字段文档化；
- `layout` 只适合放在 Theme V2 / page override 语境中；
- `featured` / `pinned` / `search` / `toc` 当前不应写成首次用户可稳定依赖的正式 frontmatter 字段。

首版文档必须以当前实现边界为准，而不是按愿望扩写。

## Product Shape Of `docs/moonink/`

`docs/moonink/` 应该同时是：

- 一套对首次用户友好的 product docs；
- 一个可以直接构建的 MoonInk vault；
- 一个展示现有 feature 的 demo showcase。

这意味着它不能只是信息堆叠；它必须主动展示：

- page / article 的差异；
- internal links 与 backlinks；
- Obsidian vault 兼容路径；
- asset copy 行为；
- `pretty` / `direct` route 概念；
- Theme V2 的最小 authoring model；
- `check` 与 `serve` 的真实边界。

## Information Architecture

建议的目录树如下：

```text
docs/moonink/
  moonink.json
  index.md
  getting-started/
    index.md
    install.md
    first-site.md
  guide/
    index.md
    content-model.md
    cli.md
    check-and-serve.md
    config.md
    frontmatter.md
    linking-and-assets.md
    obsidian-vault.md
    routing-and-output.md
    theme-v2.md
  examples/
    index.md
    minimal-site.md
    docs-site.md
    obsidian-vault.md
  migration/
    index.md
    from-markdown-folder.md
    from-obsidian-vault.md
  reference/
    index.md
    cli-reference.md
    config-reference.md
    frontmatter-reference.md
    theme-reference.md
  compare/
    index.md
    quartz.md
    mkdocs.md
  faq.md
  public/
    *.svg / *.png / *.txt
  assets/
    *.png / *.svg
```

## Page Strategy

### 1. Page Type Policy Inside The Docs Vault

- 各 section 的 `index.md` 使用 `type: page`，承担 landing / hub 作用；
- 大部分深度 Guide 页面保持 article 默认形态，用来展示 built-in article surface、TOC、related reading、backlinks；
- `compare/` 页面可以使用 article 形态，以获得更完整的阅读体验；
- `faq.md` 保持 page 或 article 均可，但首选 `type: page`，便于扫描式阅读。

### 2. Root Homepage Policy

根首页必须显式使用 `index.md`，而不是依赖 `README.md` fallback。原因：

- 首版文档站需要稳定 landing page；
- `README.md` fallback 应作为被解释的功能，而不是本站自己的主路径实现方式。

## Required Page Inventory

下表定义首版文档的目标页面与职责。

| Path | 推荐标题 | Kind | 角色 | 必须覆盖内容 |
| --- | --- | --- | --- | --- |
| `index.md` | 月墨 / MoonInk | page | landing home | 产品定位、支持场景、两条开始路径、`check` / `serve` 入口、Theme V2 推荐路径 |
| `getting-started/index.md` | 快速开始 | page | start hub | 安装、初始化、首次构建、下一步导航 |
| `getting-started/install.md` | 安装 MoonInk | article | install guide | GitHub Releases binary install、源码运行方式、必要前置条件 |
| `getting-started/first-site.md` | 第一个站点 | article | golden path | `onboard`、`build`、`check`、`serve`、输出目录 |
| `guide/index.md` | 使用指南 | page | guide hub | Guide 导航、推荐阅读顺序 |
| `guide/content-model.md` | 内容模型 | article | concepts | article / page 区分、首页推断、`README.md` fallback 规则 |
| `guide/cli.md` | CLI 命令 | article | command overview | 五个命令的职责、常见调用方式、何时用 `check` |
| `guide/check-and-serve.md` | 检查与预览 | article | workflow guide | `check` 的定位、warning / error 行为、`serve` native-only 边界 |
| `guide/config.md` | 配置文件 | article | config guide | `moonink.json` 基本结构、常用字段、推荐默认值 |
| `guide/frontmatter.md` | 页面元数据 | article | content authoring | 稳定 frontmatter 字段、何时使用 `type: page`、`draft` |
| `guide/linking-and-assets.md` | 链接与资源 | article | linking guide | Markdown links、WikiLink、embed、`public/`、content-tree asset |
| `guide/obsidian-vault.md` | Obsidian Vault | article | vault guide | `.obsidian` 排除、vault 根构建、README fallback、资源链接 |
| `guide/routing-and-output.md` | 路由与输出 | article | output guide | `pretty` / `direct`、输出目录结构、首页规则 |
| `guide/theme-v2.md` | Theme V2 | article | theme guide | 推荐主题路径、manifest、layouts、partials、tokens、slots |
| `examples/index.md` | 示例 | page | example hub | 三类示例入口 |
| `examples/minimal-site.md` | 最小站点示例 | article | example | 最小 `moonink.json`、最小内容树 |
| `examples/docs-site.md` | 文档站点示例 | article | example | page / article 混合、导航、资源 |
| `examples/obsidian-vault.md` | Vault 示例 | article | example | Obsidian 目录、图片资源、WikiLink |
| `migration/index.md` | 迁移与接入 | page | migration hub | 两类接入路径 |
| `migration/from-markdown-folder.md` | 从 Markdown Folder 接入 | article | migration | 现有 folder 接入步骤、最小改动策略 |
| `migration/from-obsidian-vault.md` | 从 Obsidian Vault 接入 | article | migration | 现有 vault 接入步骤、常见注意事项 |
| `reference/index.md` | 参考 | page | reference hub | Reference 导航 |
| `reference/cli-reference.md` | CLI Reference | article | reference | 命令、参数、默认行为、返回边界 |
| `reference/config-reference.md` | Config Reference | article | reference | `moonink.json` 字段表 |
| `reference/frontmatter-reference.md` | Frontmatter Reference | article | reference | 稳定 frontmatter 字段表 |
| `reference/theme-reference.md` | Theme Reference | article | reference | Theme V2 manifest key 与目录 contract |
| `compare/index.md` | 对比 | page | compare hub | 对比页入口 |
| `compare/quartz.md` | MoonInk 与 Quartz | article | compare | 定位差异、当前适用场景、取舍 |
| `compare/mkdocs.md` | MoonInk 与 MkDocs | article | compare | 内容模型、站点定位、工作流差异 |
| `faq.md` | FAQ | page | support | 初始化、构建、检查、预览、Vault 兼容、主题常见问题 |

## Writing Rules

### 1. Language And Tone

- 以简体中文为主体；
- English nouns 保留原词：command、build、check、serve、Theme V2、frontmatter、route style 等；
- 命令、路径、JSON key、frontmatter key 一律保持英文原样；
- 文风以 product docs 为准：准确、平静、边界清晰、少行话、少 contributor 口吻。

### 2. Page Title And Filename Policy

- 页面标题偏中文；
- 文件名使用稳定、可预测的 ASCII slug；
- 不使用中文文件名作为主 slug；
- 目录页统一使用 `index.md`。

### 3. Structure Policy

- 每页开头给出 1 段简短摘要；
- 每页只承担一个主要问题；
- Example 与 Reference 分离：Guide 解释“怎么做”，Reference 给出字段与参数表；
- Compare 页面谈定位和取舍，不写营销文案。

### 4. Truthfulness Policy

- 不得把未实现能力写成已支持；
- 不得把 legacy path 写成推荐主路径；
- 不得从旧文档复制过时表述，例如 “scaffold phase”；
- 不得依赖仓库外部 URL 作为安装步骤，除非用户明确提供真实分发地址。

### 5. Link Policy Inside The Vault

- 内部页面优先使用 MoonInk 当前支持的链接方式；
- 至少部分页面要使用 `[[WikiLink]]` 互链，以展示当前能力；
- 关键概念页面之间应故意形成 backlink 网络，而不是孤立文档树。

## Showcase Requirements

`docs/moonink/` 不是纯文字手册，必须主动展示当前功能。首版至少展示：

- page 与 article 的不同展示；
- `[[WikiLink]]` 与 `[[target|label]]`；
- 图片 embed 与普通资源链接；
- `public/` 资源与内容树资源；
- `pretty` / `direct` 的 URL 差异；
- `draft` 的语义说明；
- built-in default theme 的 article reading surface；
- backlinks 能力。

展示方式要求：

- 通过正常页面互链来触发 backlinks；
- 通过真实存在的资源文件来演示 embed / asset copy；
- 通过静态代码片段说明 `check` 诊断样式，而不是故意让文档站本身处于 invalid 状态。

## Example Strategy

### 1. Config Examples

至少准备三类 snippet：

- 最小 `moonink.json`；
- Obsidian-friendly `moonink.json`；
- Theme V2 `moonink.json`（使用 `theme` / `theme_config` 的推荐路径）。

### 2. Frontmatter Examples

至少准备三类 snippet：

- page frontmatter；
- article frontmatter；
- article metadata frontmatter（含 `summary` / `updated` / `series` / `cover` / `author` / `column` / `tags` / `draft`）。

### 3. CLI Examples

必须同时给出：

- installed binary 形式：`moonink ...`；
- repo source-run 形式：`moon run src/cmd/main -- ...`。

binary install 章节的发布来源固定为 GitHub Releases：`github.com/Kozmosa/moonink`。实际安装命令、平台说明、压缩包名称与解压后的可执行文件名，需要在真正撰写安装页时以 release 页面中的真实 artifact 为准。

## Internal Source Map For Rewriting

以下文件可以作为作者写作时的事实来源，但不能在最终站点中被直接引用：

| Internal source | 用途 | 处理方式 |
| --- | --- | --- |
| `README.mbt.md` | CLI 概览、native serve 说明 | 重写，不保留旧 `scaffold phase` 口吻 |
| `docs/technical/03-Configuration-Design.md` | config 说明 | 重写为用户导向 guide / reference |
| `docs/technical/05-Routing-and-Navigation.md` | route / output 规则 | 重写为用户导向 guide |
| `docs/technical/06-Markdown-and-Frontmatter.md` | frontmatter 事实 | 重写，只保留 shipped 内容 |
| `docs/technical/07-Linking-and-WikiLink.md` | linking / asset 行为 | 重写，加入用户例子 |
| `docs/technical/08-Theme-System.md` | theme 总体边界 | 重写为 Theme V2 guide / reference |
| `docs/technical/10-CLI-and-Dev-Server.md` | `check` / `serve` 行为 | 重写，突出 `check` first-class 与 native-only |
| `fixtures/v2/` | examples 与 snippets | 复制思想，不直接引用原 fixture 作为站内内容 |
| `src/core/*`, `src/cli/*`, `src/runtime/*` | 最终真值边界 | 作为最终核对来源 |

以下来源应视为过时或不可直接沿用：

- `README.mbt.md` 中 “scaffold phase” 的帮助文案；
- 任何把旧 `new` 命令或非当前命令面写成主路径的材料；
- 任何把未落地 search product、hosting、future metadata contract 当成已支持能力的材料。

## Acceptance Criteria

当实际开始撰写 `docs/moonink/` 时，完成标准至少包括：

1. `docs/moonink/moonink.json` 存在，且 `docs/moonink/` 可作为独立 vault 构建。
2. 从仓库根目录运行 `moonink build --config docs/moonink/moonink.json` 或等价 source-run 命令时可以成功构建。
3. 从仓库根目录运行 `moonink check --config docs/moonink/moonink.json` 或等价 source-run 命令时返回成功状态。
4. 所有站内页面都只链接 `docs/moonink/` 内部页面或本站资源，不依赖仓库现有文档路径。
5. Quick Start、Guide、Reference、FAQ 中都能找到 `check`。
6. 所有 `serve` 相关页面都明确标注 `native-only`。
7. Theme V2 作为推荐主题路径被完整覆盖。
8. 文档中不把 `featured` / `pinned` / `search` / `toc` / `nav_title` / `nav_hidden` 写成正式稳定字段。
9. 文档站自身展示 internal links、backlinks、asset copy、page / article 混合、Vault 兼容等能力。
10. 文档的 landing page 具备明确产品首页结构，而不是纯索引页。

## Recommended Implementation Order

后续真正开始写 `docs/moonink/` 时，建议顺序为：

1. 先落 `moonink.json`、根首页和 section index 页面，形成 buildable skeleton。
2. 再完成 Quick Start、核心 Guide、核心 Reference。
3. 再补 Examples、Migration、Compare、FAQ。
4. 最后统一做 internal linking、backlink network、asset showcase 与 wording polish。

## Final Note

这份 spec 的核心约束不是“把所有能力都写进去”，而是“把首次用户真正能依赖的能力，组织成一个独立、可构建、可展示的文档 vault”。

如果未来需要加入 binary install 的真实步骤、legacy compatibility appendix 或更广的 feature surface，应在已有独立 vault 成型之后再扩展，而不是在首版里混入不确定信息。
