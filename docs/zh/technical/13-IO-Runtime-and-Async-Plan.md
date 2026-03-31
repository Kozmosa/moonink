# 13 IO 运行时与异步重构计划

## 1. 目的

本文定义 MoonInk 在近期的 IO 工程方向，将当前已经明确的项目决策转化为可执行的重构计划：

- 文件系统访问以 `moonbitlang/x/fs` 作为当前基础能力；
- `native` 是必须优先支持的一等目标；
- 现有 IO 应渐进式向 async 运行时模型重构；
- 解析、建模、渲染等核心逻辑应尽量保持同步、纯净、可测试。

## 2. 当前约束集

### 2.1 已确认约束

- MoonInk 必须支持 `native` target；
- 文件系统操作统一建立在 `moonbitlang/x/fs` 之上；
- IO 重构方向应优先走向 async，而不是继续扩张同步直连调用。

### 2.2 架构含义

MoonInk 不应让文件系统细节渗透到整个代码库中。项目应形成如下分离：

- 同步核心逻辑：负责解析、规范化、路由、建模等纯计算；
- 异步运行时边界：负责文件系统以及未来可能出现的外部 IO。

## 3. 设计原则

### 3.1 native 优先，但不把 native 细节铺满全局

当前实现应围绕 `native` 优化，但不要把 native 专属细节硬编码进高层构建逻辑。native 专属行为应被收敛在单独的 runtime 层中。

### 3.2 `x/fs` 是能力来源，不是全部架构

`moonbitlang/x/fs` 是当前文件系统能力提供者，但 MoonInk 仍应在其外层建立自己的 IO facade，以便：

- 统一错误模型；
- 统一路径与编码策略；
- 控制 async 演进方式；
- 避免上层模块散落原始文件系统调用；
- 为后续测试和替身实现保留清晰边界。

### 3.3 核心尽量保持同步

以下区域原则上保持同步，除非有充分理由改为 async：

- 文本载入之后的配置解析；
- 内容分类与规范化逻辑；
- frontmatter 与 Markdown 转换；
- 路由、导航与站点模型构建；
- 不依赖外部 IO 的渲染决策。

### 3.4 把等待留在边界

以下区域是 async 化的正确边界：

- 文件读取与写入；
- 目录遍历；
- workspace 与项目根探测；
- 未来 dev server 的 socket / stream IO；
- 后续可能引入的外部命令或进程 IO。

## 4. 目标分层

MoonInk 应逐步演进为如下执行结构：

1. CLI 层
2. runtime / IO facade 层
3. 配置与内容摄取层
4. 解析与规范化层
5. 站点模型层
6. 渲染层
7. 输出层

这里的关键变化是：runtime IO 从嵌入式实现演进为显式边界，而不是继续直接散落在各个 feature module 中。

## 5. 首轮重构范围

第一轮 IO 重构优先覆盖当前已经真实落地的文件系统触点：

- `new` 命令中的 starter project 写入；
- `moonink.toml` 的加载；
- `docs/` 与 `articles/` 下的递归内容发现。

这些操作已经具备真实、边界清晰、风险可控的特征，适合作为第一批迁移对象。

## 6. 本轮非目标

本路线图当前不打算立即完成以下事项：

- 重设计对外 CLI surface；
- 把所有内部函数一口气都改成 async；
- 在 `native` 稳定之前，为全部 target 建立完整统一抽象；
- 过早引入插件式 runtime hook；
- 在同一个提交里同时解决 dev server 并发与基础文件系统重构。

## 7. 分阶段原子提交路线图

### IO-P0: Writing Plan

编写并冻结 IO 重构计划、约束和迁移护栏。

### IO-P1: Inventory Existing IO Surface

登记所有文件系统与 IO 触点、调用方以及迁移优先级。

### IO-P2: Define IO Layer Boundaries

文档化并引入专门的 runtime 或 IO facade 边界，阻止 feature module 继续增长原始文件系统调用。

### IO-P3: Introduce Unified IO Error Model

将文件系统相关错误统一映射为项目自有错误类型。

### IO-P4: Introduce Path And Encoding Policy

在更大范围的 async 迁移之前，先固定路径规范与文本编码规则。

### IO-P5: Add Sync Facade Over `x/fs`

先在当前 `x/fs` 之上封装 MoonInk 自有 helper API，而不立刻重写整条调用链。

### IO-P6: Introduce Async IO Interface

为 native runtime 增加第一版 async IO facade。

### IO-P7: Migrate Read Operations First

优先迁移配置与源文件读取路径。

### IO-P8: Migrate Write Operations With Safety Guarantees

在读取路径稳定后迁移写路径，并加入必要的输出安全保障。

### IO-P9: Migrate Directory And Workspace Loading

把递归发现与项目根扫描迁移到 runtime IO 边界。

### IO-P10: Introduce Native Runtime Adaptation Layer

隔离 native 专属 runtime 接线，使高层模块尽量保持 target 无关。

### IO-P11: Remove Direct Synchronous IO Entrypoints

废弃并清理 feature module 中残留的同步直连文件系统入口。

### IO-P12: Add Tests For Async IO Contracts

覆盖成功路径、缺失文件、遍历失败以及错误映射等关键行为。

### IO-P13: Add Concurrency And Cancellation Policy

定义冲突处理、取消语义以及未来 runtime 调度规则。

### IO-P14: Documentation And Migration Closure

更新架构文档、协作规范与迁移说明，使新模型成为默认工程路径。

## 8. 里程碑

### M1 - 决策与边界冻结

覆盖 `IO-P0` 到 `IO-P4`。

目标：在代码 churn 扩大之前，先固定约束、边界、错误模型与策略。

### M2 - facade 建立

覆盖 `IO-P5` 到 `IO-P6`。

目标：在大规模迁移前，先让 runtime IO 边界真实存在。

### M3 - 主干迁移

覆盖 `IO-P7` 到 `IO-P10`。

目标：把当前已有的读、写、发现流程迁移到新 runtime 模型。

### M4 - 收敛与稳定化

覆盖 `IO-P11` 到 `IO-P14`。

目标：清理遗留路径、补齐测试，并完成面向协作者的最终说明。

## 9. 完成信号

当以下条件成立时，可认为 IO 重构主线成功建立：

- 新功能开发不再在 feature module 中直接新增原始 `x/fs` 调用；
- runtime 文件系统访问具备单一、项目自有的边界；
- native 下的第一条真实 async 路径已经落地；
- 同步核心依然保持清晰、可读、可测试；
- 架构与路线图文档已经清楚描述新的执行模型。
