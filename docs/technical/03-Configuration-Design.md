# 03 Configuration Design

## 1. Format Choice

MoonInk V1 uses TOML as its main project configuration format.

## 2. Design Principles

- easy to read manually;
- deterministic to parse;
- explicit over magical defaults;
- small schema in V1.

## 3. Expected Core Sections

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

## 4. Required And Optional Fields

### Required

- site name
- content roots or default content root
- build output directory

### Optional

- site URL
- theme settings
- navigation override
- search settings

## 5. Validation Rules

Validation should catch:

- missing required sections;
- invalid path references;
- duplicate route definitions;
- malformed navigation entries;
- conflicting page identifiers.

## 6. Compatibility Position

MoonInk does not attempt first-release compatibility with `mkdocs.yml`, but it should preserve familiar concepts such as site metadata, navigation, theme settings, and output directory definition.
