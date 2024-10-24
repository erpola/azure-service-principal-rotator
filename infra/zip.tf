data "archive_file" "func" {
  type        = "zip"
  source_dir  = "../func"
  output_path = "./deployments/func.zip"

  excludes = [
    "**/__pycache__/**",
    "**/*.pyc",
    "**/local.settings.json",
    "**/bin/**",
    "**/obj/**",
    "**/.venv/**",
    ".env",
    ".vscode/**",
    ".git/**",
    ".gitignore",
    ".DS_Store",
  ]
}