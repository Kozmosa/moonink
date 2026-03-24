# 00 架构总览

## 1. 目的

本文档定义 MoonInk V1 的整体架构，包括主要模块、数据流，以及内容处理与站点生成之间的关系。

## 2. 架构原则

- 以内容为先，而不是以主题为先；
- 采用显式阶段，而不是隐藏耦合；
- 优先强默认值，而不是过早开放扩展；
- 采用适合 MoonBit 的模块化，而不是框架式抽象。

## 3. 系统分层

MoonInk V1 划分为以下层次：

1. CLI 层
2. 配置层
3. 内容摄取层
4. 解析与规范化层
5. 站点模型层
6. 渲染层
7. 输出层

## 4. 高层流程

```text
CLI Command
  -> Config Load And Validation
  -> Content Discovery
  -> Frontmatter Parse
  -> Markdown Parse
  -> Route + Identity Normalize
  -> Link Resolve And Validate
  -> Navigation + Site Model Build
  -> Theme Render
  -> HTML/Assets/Search Index Emit
```

## 5. 主要模块

- `cli`：命令解析与面向用户的执行入口
- `config`：站点配置模式与校验
- `content`：文件扫描、分类与内容加载
- `frontmatter`：元数据提取
- `markdown`：Markdown 到 AST 或中间表示的解析
- `links`：相对链接与 WikiLink 解析
- `routing`：路由生成与规范 URL 决策
- `nav`：导航模型生成
- `model`：全站模型与页面模型
- `theme`：官方主题模板与渲染辅助
- `render`：从模型到输出制品的转换
- `search`：静态搜索索引生成
- `serve`：本地开发服务器

## 6. 数据模型演进

构建过程应经历逐步精化的数据表示：

- 原始文件
- 已解析的源文档
- 规范化后的页面输入
- 站点页面模型
- 渲染后的页面输出

这种演进方式允许每个阶段独立测试。

## 7. 为什么采用此架构

该架构能够保持实现清晰、支持未来插件钩子，并且非常适合项目申报材料中的技术路线说明，因为它可以明确解释模块结构与处理流程。
