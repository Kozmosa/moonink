# username/moonink

## MoonInk CLI Scaffold

This repository implements the MoonInk static site generator.

Implemented pieces:

- `moonink help`
- `moonink onboard`
- `moonink build`
- `moonink serve`

Current status:

- command parsing is wired through the root package;
- `cmd/main` reads real runtime argv;
- `onboard` creates starter config in-place and injects default frontmatter into markdown files that lack it;
- `build` loads config, discovers content, parses frontmatter, and classifies `.html` plus `type: page` markdown as pages while other markdown remains article content;
- DocFlow build now runs an explicit parser -> WikiLinker -> render -> template pipeline with route-aware pretty/direct HTML emission;
- WikiLinker rewrites Obsidian-style `[[target]]` and `[[target|label]]` syntax using build-time route metadata, leaving unresolved or ambiguous links in place with diagnostics;
- site assembly now derives automatic page-only navigation, `nav_title`, and `nav_hidden` metadata for templates and default layout rendering;
- template rendering supports either the built-in page template or a configured `template_file`, with flat string variables including `site_name`, `page_title`, `navigation_html`, `current_section_title`, `current_section_url`, `page_header_title`, and `page_header_html`;
- the built-in template now renders automatic navigation plus section/breadcrumb context for pages and section landing pages while articles stay outside the navigation tree;
- `serve` remains a placeholder module.
