///|
/// Placeholder plan for `moonink new` during the scaffold phase.
pub(all) struct StarterTemplatePlan {
  project_name : String
  created_paths : Array[String]
  note : String
} derive(Show, Eq)

///|
pub fn plan_starter_project(project_name : String?) -> StarterTemplatePlan {
  let resolved_name = match project_name {
    Some(name) => name
    None => "moonink-site"
  }
  {
    project_name: resolved_name,
    created_paths: [
      "moonink.toml",
      "docs/index.md",
      "articles/hello.md",
      "theme/README.md",
      ".gitignore",
    ],
    note: "Starter project generation is still a placeholder in the scaffold stage.",
  }
}

///|
fn run_new_command(project_name : String?) -> CliOutcome {
  let plan = plan_starter_project(project_name)
  {
    exit_code: 0,
    message:
      "[new] scaffold ready\nproject: \{plan.project_name}\nplanned files: 5\nstatus: placeholder only",
  }
}
