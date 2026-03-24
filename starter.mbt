///|
/// A single file planned for emission by `moonink new`.
pub(all) struct StarterTemplateFile {
  path : String
  summary : String
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
fn starter_template_files() -> Array[StarterTemplateFile] {
  [
    {
      path: "moonink.toml",
      summary: "Core TOML configuration with site, content, theme, and build sections.",
    },
    {
      path: "docs/index.md",
      summary: "Documentation landing page for stable notes and reference content.",
    },
    {
      path: "docs/getting-started.md",
      summary: "Starter documentation page showing the docs track structure.",
    },
    {
      path: "articles/hello-moonink.md",
      summary: "Sample article demonstrating the parallel publishing track.",
    },
    {
      path: "theme/README.md",
      summary: "Theme notes describing the official starter customization surface.",
    },
    {
      path: "theme/overrides.css",
      summary: "A minimal override stylesheet for light visual adjustments.",
    },
    {
      path: ".gitignore",
      summary: "Ignore generated site output and local preview artifacts.",
    },
  ]
}

///|
pub fn plan_starter_project(project_name : String?) -> StarterTemplatePlan {
  let resolved_name = resolve_project_name(project_name)
  {
    project_name: resolved_name,
    root_dir: resolved_name,
    created_files: starter_template_files(),
    content_roots: ["docs", "articles"],
    theme_dir: "theme",
    note:
      "Starter template now models the Phase 1 sample MoonInk site layout, while file emission remains a later side-effecting step.",
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
