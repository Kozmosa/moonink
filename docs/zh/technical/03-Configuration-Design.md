# 03 配置设计

## 1. 格式选择

MoonInk V1 使用 TOML 作为项目主配置格式。

## 2. 设计原则

- 便于人工阅读；
- 解析结果确定；
- 显式优于“魔法默认值”；
- V1 采用较小的配置模式。

## 3. 预期核心分区

```toml
[site]
name = "MoonInk Example"
url = "https://example.com"

[content]
docs = "docs"
articles = "articles"

[theme]
name = "default"

[build]
output = "site"
```

## 4. 必填与可选字段

### 必填

- 站点名称
- 内容根目录或默认内容根目录
- 构建输出目录

### 可选

- 站点 URL
- 主题设置
- 导航覆盖配置
- 搜索设置

## 5. 校验规则

校验应捕获以下问题：

- 缺失必需分区；
- 非法路径引用；
- 重复路由定义；
- 格式错误的导航条目；
- 冲突的页面标识。

## 6. 兼容性立场

MoonInk 第一版不追求与 `mkdocs.yml` 兼容，但会保留一些熟悉的概念，例如站点元数据、导航、主题设置以及输出目录定义。
