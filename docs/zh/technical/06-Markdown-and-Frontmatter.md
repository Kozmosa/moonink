# 06 Markdown 与 Frontmatter

## 1. 输入模型

MoonInk V1 接受带可选 frontmatter 的 Markdown 文件。

## 2. Frontmatter 的作用

frontmatter 提供页面元数据，这些元数据将用于渲染、路由、导航与搜索。

## 3. V1 支持的元数据

- `title`
- `id`
- `author`
- `tags`
- `date`

## 4. 解析职责

解析器应区分以下职责：

- 元数据提取；
- 正文提取；
- Markdown 解析；
- 若未来引入摘要或阅读信息，则再处理派生字段。

## 5. 解析约束

V1 应优先支持一个较小且确定的 Markdown 特性集。复杂嵌入式组件或可执行块应后置。

## 6. 错误处理

格式错误的 frontmatter 应产生可操作的诊断信息，并包含文件路径上下文。
