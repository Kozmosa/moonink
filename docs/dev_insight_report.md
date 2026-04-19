# 开发心得体会

在 Theme System V2 的开发过程中，我遇到的一个典型 Bug，并不是简单的语法错误，而是主题解析语义的漂移。MoonInk 在此之前已经支持基于 `layout.html` 和 `template_file` 的 legacy 模板路径；而引入 Theme V2 之后，系统又新增了 manifest-driven theme bundle，同时还需要在用户没有项目主题时提供 built-in fallback。随着这三条路径并存，问题开始暴露出来：有些站点在 `check` 阶段和 `build` 阶段对同一份配置给出不同结论，有些项目明明应该走 Theme V2，却被旧模板路径截走，导致最终渲染结果和预期不一致。

定位这个问题时，我没有直接删除兼容层，而是先把整个主题解析过程拆成几个独立部分：bundle 加载、legacy 模板选择、fallback 触发条件，以及页面级 layout 选择。通过逐步对照，我确认根因不是某一个单点实现错误，而是多套兼容路径之间的职责边界不够清晰，导致逻辑互相渗透。解决时，我把责任重新收拢：`runtime` 负责 theme bundle 的加载和文件合法性校验，CLI preflight 负责页面级的 layout 选择与 override 校验；项目存在明确主题或模板时优先走项目路径，只有在不存在项目 bundle 或 legacy override 的情况下，才进入 built-in Theme V2 fallback。这样处理之后，`check` 与 `build` 的行为重新对齐，主题选择逻辑也更稳定可预测。

这个 Bug 的处理过程，也推动了一个关键技术决策：Theme System V2 不能继续在单一 `layout.html` 的基础上不断打补丁，但也不适合一次性废弃 legacy 模板，而应该采用 manifest-driven theme bundle，同时保留 legacy compatibility 和 built-in fallback。具体场景是，MoonInk 需要支持 `index`、`page`、`article` 等不同页面类型的稳定布局契约，还要支持 token、page override、slot 等更加结构化的主题能力。如果继续沿用旧模板路径扩展，布局语义会越来越隐式，测试和维护成本都会快速上升；如果直接切断 legacy 路径，已有项目就必须整体迁移，工程代价过高。因此我最终选择了“新合同前移、旧接口保留”的方案：用 Theme V2 承担长期结构能力，用兼容层控制迁移成本。这次实践让我更明确，好的技术决策不只是追求设计上更先进，还要保证系统能够平稳演进。

MoonBit 工具链在这个过程中提供了很直接的帮助。Theme V2 横跨 `core`、`docflow`、`runtime`、`cli` 多个包，`moon check` 和 `moon test` 可以帮助我快速确认跨包类型与行为没有失配；`moon info` 会刷新 `.mbti` 接口文件，让“这次改动是否已经影响到包外契约”变得非常直观；`moon fmt` 则保证了大规模修改后的代码仍然保持统一风格。更重要的是，MoonBit 的包结构和接口机制也反过来影响了我的实现方式：我不能把主题加载、页面契约校验和模板控制流全部塞进一个入口函数里，而必须将核心模型、运行时加载和 CLI 预检拆开。这让我感受到，MoonBit 工具链不仅提高了开发效率，也推动我把系统做成边界清晰、可验证、可演进的工程结构。
