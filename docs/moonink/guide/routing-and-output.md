---
title: 路由与输出
summary: MoonInk 目前支持 pretty 和 direct 两种 route style，它们决定了 URL 形态，也决定了 dist 目录的组织方式。
tags: [guide, routing]
---

route style 看起来只是一个 config 字段，但它会影响你看到的 URL、输出树、以及某些调试习惯。

## `pretty` 和 `direct`

| 源文件 | `pretty` | `direct` |
| --- | --- | --- |
| `index.md` | `/` | `/` |
| `hello.md` | `/hello/` | `/hello.html` |
| `guide/install.md` | `/guide/install/` | `/guide/install.html` |

如果你更偏向静态站点常见的目录 URL，选择 `pretty`。如果你明确想保留 `.html` 文件路径，选择 `direct`。

## 配置方式

```json
{
  "route_style": "pretty"
}
```

```json
{
  "route_style": "direct"
}
```

## 输出目录是什么样

`pretty` 常见输出：

```text
dist/
  index.html
  guide/
    install/
      index.html
```

`direct` 常见输出：

```text
dist/
  index.html
  guide/
    install.html
```

## 和首页规则的关系

- 根 `index.*` 始终映射到 `/`
- 没有根 `index.*` 时，根 `README.md` 会被提升为首页

所以首页规则不依赖 `pretty` / `direct`；它只影响非首页页面的输出形态。

## 和资源复制的关系

route style 不改变资源复制规则：

- 内容树资源照常复制
- `public/` 照常复制到输出根

相关主题：

- [[content-model]]
- [[linking-and-assets]]
- [[config-reference]]
