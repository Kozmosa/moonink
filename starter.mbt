///|
/// A single file planned for emission by `moonink new`.
pub(all) struct StarterTemplateFile {
  path : String
  summary : String
  content : String
} derive(Show, Eq)

///|
/// Concrete starter-project layout for the current `moonink new` planning stage.
pub(all) struct StarterTemplatePlan {
  project_name : String
  root_dir : String
  created_files : Array[StarterTemplateFile]
  content_roots : Array[String]
  theme_dir : String
  note : String
} derive(Show, Eq)

///|
fn resolve_project_name(project_name : String?) -> String {
  match project_name {
    Some(name) => name
    None => "moonink-site"
  }
}

///|
fn moonink_toml_content(project_name : String) -> String {
  "[site]\nname = \"\{project_name}\"\nurl = \"https://example.com\"\n\n[content]\ndocs = \"docs\"\narticles = \"articles\"\n\n[theme]\nname = \"default\"\n\n[build]\noutput = \"site\"\n"
}

///|
fn docs_index_content(project_name : String) -> String {
  "---\ntitle: Home\nsummary: Welcome to the MoonInk starter project.\n---\n\n# \{project_name}\n\n" +
  (
    #|This is the documentation track of your new MoonInk project.
    #|
    #|- Keep stable reference material under `docs/`.
    #|- Write time-based posts or essays under `articles/`.
    #|- Run `moonink build` when the static generator pipeline is implemented.
    #|
    #|Continue with [Getting Started](getting-started.md).
    #|
  )
}

///|
fn docs_getting_started_content() -> String {
  let content =
    #|---
    #|title: Getting Started
    #|summary: First steps after creating a new MoonInk site.
    #|---
    #|
    #|# Getting Started
    #|
    #|Suggested next steps:
    #|
    #|1. Update `moonink.toml` with your real site metadata.
    #|2. Replace this page with your own documentation outline.
    #|3. Add more notes under `docs/` and articles under `articles/`.
    #|4. Customize `theme/overrides.css` to adjust the visual style.
    #|
  content
}

///|
fn article_hello_content() -> String {
  let content =
    #|---
    #|title: Hello MoonInk
    #|summary: First article in the starter content tree.
    #|---
    #|
    #|# Hello MoonInk
    #|
    #|This sample article demonstrates the article track that sits beside `docs/`.
    #|
    #|Use this area for changelogs, essays, or updates that should read more like posts.
    #|
  content
}

///|
fn theme_readme_content() -> String {
  let content =
    #|# Theme Overrides
    #|
    #|This directory is reserved for the official MoonInk theme customization surface.
    #|
    #|- `overrides.css` is a safe place for small visual adjustments.
    #|- Later versions of MoonInk may add templates, partials, or theme metadata here.
    #|
  content
}

///|
fn theme_overrides_content() -> String {
  let content =
    #|:root {
    #|  --moonink-accent: #5b6df8;
    #|}
    #|
    #|body {
    #|  text-rendering: optimizeLegibility;
    #|}
    #|
  content
}

///|
fn gitignore_content() -> String {
  let content =
    #|site/
    #|.DS_Store
    #|
  content
}

///|
fn starter_template_files(project_name : String) -> Array[StarterTemplateFile] {
  [
    {
      path: "moonink.toml",
      summary: "Core TOML configuration with site, content, theme, and build sections.",
      content: moonink_toml_content(project_name),
    },
    {
      path: "docs/index.md",
      summary: "Documentation landing page for stable notes and reference content.",
      content: docs_index_content(project_name),
    },
    {
      path: "docs/getting-started.md",
      summary: "Starter documentation page showing the docs track structure.",
      content: docs_getting_started_content(),
    },
    {
      path: "articles/hello-moonink.md",
      summary: "Sample article demonstrating the parallel publishing track.",
      content: article_hello_content(),
    },
    {
      path: "theme/README.md",
      summary: "Theme notes describing the official starter customization surface.",
      content: theme_readme_content(),
    },
    {
      path: "theme/overrides.css",
      summary: "A minimal override stylesheet for light visual adjustments.",
      content: theme_overrides_content(),
    },
    {
      path: ".gitignore",
      summary: "Ignore generated site output and local preview artifacts.",
      content: gitignore_content(),
    },
  ]
}

///|
pub fn plan_starter_project(project_name : String?) -> StarterTemplatePlan {
  let resolved_name = resolve_project_name(project_name)
  {
    project_name: resolved_name,
    root_dir: resolved_name,
    created_files: starter_template_files(resolved_name),
    content_roots: ["docs", "articles"],
    theme_dir: "theme",
    note:
      "Starter template now models the Phase 1 sample MoonInk site layout and can be emitted by the runtime CLI entry.",
  }
}

///|
fn append_unique_path(paths : Array[String], path : String) -> Unit {
  if paths.search_by(existing => existing == path) is None {
    paths.push(path)
  }
}

///|
fn directory_prefixes(path : String) -> Array[String] {
  let prefixes = []
  let segments = path.split("/")
  let mut current = if path.has_prefix("/") { "/" } else { "" }
  for segment_view in segments {
    let segment = segment_view.to_string()
    if segment == "" || segment == "." {
      continue
    }
    current = if current == "" {
      segment
    } else if current == "/" {
      "/\{segment}"
    } else {
      "\{current}/\{segment}"
    }
    append_unique_path(prefixes, current)
  }
  prefixes
}

///|
fn starter_directories(plan : StarterTemplatePlan) -> Array[String] {
  let directories = directory_prefixes(plan.root_dir)
  append_unique_path(directories, plan.root_dir)
  append_unique_path(directories, "\{plan.root_dir}/docs")
  append_unique_path(directories, "\{plan.root_dir}/articles")
  append_unique_path(directories, "\{plan.root_dir}/theme")
  directories
}

///|
fn scoped_output_path(root_dir : String, relative_path : String) -> String {
  "\{root_dir}/\{relative_path}"
}

///|
pub fn emit_starter_project_runtime(plan : StarterTemplatePlan) -> CliOutcome {
  try_emit_starter_project(plan) catch {
    err => {
      exit_code: 1,
      message:
        "[new] failed to create starter project\nroot: \{plan.root_dir}\nerror: \{err}",
    }
  }
}

///|
fn try_emit_starter_project(plan : StarterTemplatePlan) -> CliOutcome raise @fs.IOError {
  if @fs.path_exists(plan.root_dir) {
    return {
      exit_code: 1,
      message:
        "[new] target directory already exists\nroot: \{plan.root_dir}\nstatus: aborted to avoid overwriting existing files",
    }
  }
  for directory in starter_directories(plan) {
    @fs.create_dir(directory)
  }
  for file in plan.created_files {
    @fs.write_string_to_file(scoped_output_path(plan.root_dir, file.path), file.content)
  }
  {
    exit_code: 0,
    message:
      "[new] starter project created\nproject: \{plan.project_name}\nroot: \{plan.root_dir}\nfiles written: \{plan.created_files.length()}\nnext: edit moonink.toml and begin writing content",
  }
}

///|
fn run_new_command(project_name : String?) -> CliOutcome {
  let plan = plan_starter_project(project_name)
  {
    exit_code: 0,
    message:
      "[new] starter template planned\nproject: \{plan.project_name}\nroot: \{plan.root_dir}\nfiles: \{plan.created_files.length()}\ncontent roots: docs, articles\ntheme dir: \{plan.theme_dir}\nstatus: ready for file emission",
  }
}
