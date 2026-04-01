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
/// A single concrete write target derived from the starter template plan.
pub(all) struct StarterWriteTarget {
  output_path : String
  summary : String
  content : String
} derive(Show, Eq)

///|
/// Safe write plan for starter emission introduced by IO-P8.
pub(all) struct StarterWritePlan {
  root_dir : String
  directories : Array[String]
  files : Array[StarterWriteTarget]
  file_count : Int
  encoding : String
  overwrite_policy : String
} derive(Show, Eq)

///|
fn resolve_project_name(project_name : String?) -> String raise PathPolicyError {
  match project_name {
    Some(name) => normalize_relative_path(name)
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
  let resolved_name = resolve_project_name(project_name) catch {
    _ => "moonink-site"
  }
  {
    project_name: resolved_name,
    root_dir: resolved_name,
    created_files: starter_template_files(resolved_name),
    content_roots: ["docs", "articles"],
    theme_dir: "theme",
    note: "Starter template now models the Phase 1 sample MoonInk site layout and can be emitted by the runtime CLI entry with normalized relative paths and UTF-8 text files.",
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
  let normalized = normalize_relative_path(path) catch { _ => path }
  let prefixes = []
  let segments = normalized.split("/")
  let mut current = ""
  for segment_view in segments {
    let segment = segment_view.to_string()
    if segment == "" {
      continue
    }
    current = if current == "" { segment } else { "\{current}/\{segment}" }
    append_unique_path(prefixes, current)
  }
  prefixes
}

///|
fn starter_directories(plan : StarterTemplatePlan) -> Array[String] {
  let directories = directory_prefixes(plan.root_dir)
  append_unique_path(directories, plan.root_dir)
  append_unique_path(
    directories,
    join_relative_path(plan.root_dir, "docs") catch {
      _ => "\{plan.root_dir}/docs"
    },
  )
  append_unique_path(
    directories,
    join_relative_path(plan.root_dir, "articles") catch {
      _ => "\{plan.root_dir}/articles"
    },
  )
  append_unique_path(
    directories,
    join_relative_path(plan.root_dir, "theme") catch {
      _ => "\{plan.root_dir}/theme"
    },
  )
  directories
}

///|
fn scoped_output_path(root_dir : String, relative_path : String) -> String {
  join_relative_path(root_dir, relative_path) catch {
    _ => "\{root_dir}/\{relative_path}"
  }
}

///|
fn starter_write_targets(
  plan : StarterTemplatePlan,
) -> Array[StarterWriteTarget] {
  let targets = []
  for file in plan.created_files {
    targets.push({
      output_path: scoped_output_path(plan.root_dir, file.path),
      summary: file.summary,
      content: file.content,
    })
  }
  targets
}

///|
pub fn plan_starter_write(plan : StarterTemplatePlan) -> StarterWritePlan {
  let directories = starter_directories(plan)
  let files = starter_write_targets(plan)
  {
    root_dir: plan.root_dir,
    directories,
    files,
    file_count: files.length(),
    encoding: TEXT_ENCODING_NAME,
    overwrite_policy: "abort_if_target_exists",
  }
}

///|
fn validate_starter_write_plan(write_plan : StarterWritePlan) -> CliOutcome? {
  if io_path_exists(write_plan.root_dir) {
    return Some({
      exit_code: 1,
      message: "[new] target directory already exists\nroot: \{write_plan.root_dir}\nstatus: aborted to avoid overwriting existing files",
    })
  }
  for file in write_plan.files {
    if io_path_exists(file.output_path) {
      return Some({
        exit_code: 1,
        message: "[new] target file already exists\nroot: \{write_plan.root_dir}\npath: \{file.output_path}\nstatus: aborted before writes to preserve existing content",
      })
    }
  }
  None
}

///|
fn apply_starter_write_plan(
  write_plan : StarterWritePlan,
) -> CliOutcome raise ProjectIOError {
  for directory in write_plan.directories {
    io_create_dir(directory)
  }
  for file in write_plan.files {
    io_write_string(file.output_path, file.content)
  }
  {
    exit_code: 0,
    message: "[new] starter project created\nroot: \{write_plan.root_dir}\nfiles written: \{write_plan.file_count}\nencoding: \{write_plan.encoding}\noverwrite policy: \{write_plan.overwrite_policy}\nnext: edit moonink.toml and begin writing content",
  }
}

///|
pub fn emit_starter_project_result(plan : StarterTemplatePlan) -> CliOutcome {
  let write_plan = plan_starter_write(plan)
  match validate_starter_write_plan(write_plan) {
    Some(outcome) => outcome
    None =>
      apply_starter_write_plan(write_plan) catch {
        err =>
          {
            exit_code: 1,
            message: "[new] failed to create starter project\nroot: \{plan.root_dir}\nio error:\n\{format_project_io_error(err)}\nwrite safety: preflight completed before directory creation and file writes",
          }
      }
  }
}

///|
fn run_new_command(project_name : String?) -> CliOutcome {
  let plan = plan_starter_project(project_name)
  let write_plan = plan_starter_write(plan)
  {
    exit_code: 0,
    message: "[new] starter template planned\nproject: \{plan.project_name}\nroot: \{plan.root_dir}\nfiles: \{write_plan.file_count}\ncontent roots: docs, articles\ntheme dir: \{plan.theme_dir}\nencoding: \{write_plan.encoding}\noverwrite policy: \{write_plan.overwrite_policy}\nstatus: ready for file emission",
  }
}
