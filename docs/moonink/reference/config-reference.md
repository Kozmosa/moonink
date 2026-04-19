---
title: Config Reference
summary: 这一页列出 moonink.json 中适合首次用户稳定依赖的字段，以及一条兼容路径说明。
---

## 稳定字段

| Key | 类型 | 用途 |
| --- | --- | --- |
| `site_name` | string | 站点名称 |
| `site_url` | string | 站点 URL；在需要绝对站点地址时使用 |
| `content_dir` | string | 内容根目录 |
| `output_dir` | string | 构建输出目录 |
| `exclude` | string array | 内容发现时跳过的目录或路径模式 |
| `route_style` | string | `pretty` 或 `direct` |
| `theme` | string | 自定义主题目录路径 |
| `theme_config` | object | 传给 Theme V2 的配置对象 |

## 兼容字段

| Key | 状态 | 说明 |
| --- | --- | --- |
| `template_file` | 兼容路径 | 仍然是 shipped feature，但不是首版推荐主题主线 |

## 推荐默认值

```json
{
  "site_name": "My Site",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": ["dist"],
  "route_style": "pretty"
}
```

## 主题相关补充

- 不写 `theme`、也不写 `template_file` 时，会使用 built-in default theme
- 需要主题自定义时，优先进入 [[theme-v2|Theme V2]]
- `theme_config` 适合传 token 与 slot 值

Guide 版说明见 [[config]]。
