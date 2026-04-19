---
title: 从 Obsidian Vault 接入
summary: 把 moonink.json 放到 Vault 根，保留 README、附件和 WikiLink，然后先用 check 找出需要修正的地方。
---

Obsidian Vault 迁移的关键不是“改掉 Vault 风格”，而是让 MoonInk 正确读取现有内容根、附件和首页。

## 推荐步骤

1. 在 Vault 根放 `moonink.json`
2. 把 `.obsidian`、`Templates`、`.trash` 之类目录加进 `exclude`
3. 保留根 `README.md` 作为首页 fallback，或显式新增 `index.md`
4. 先 `check`
5. 再 `build`

## 一个常见 config

```json
{
  "site_name": "My Vault",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": [".obsidian", "dist", ".trash", "Templates"],
  "route_style": "pretty"
}
```

## 迁移时特别要看什么

- `README.md` 是否应该继续当首页
- 双中括号 WikiLink 是否都能解析
- 附件路径是否仍然指向内容树里的真实文件
- 是否有不该进入站点的草稿或模板文件

## 搭配命令

```bash
moonink check
moonink build
```

本地预览时：

```bash
moonink serve
```

但请记住，`serve` 是 `native-only`。配套指南见 [Obsidian Vault](../guide/obsidian-vault.md)。
