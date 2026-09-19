# Public release binding for the platform.
# Replace __GITHUB_USERNAME__ once the three public repositories have been created.
# Keep repository URLs and tags in this single file so a platform release is
# reproducible and does not follow the moving main branches.
$script:PlatformReleaseConfig = @{
  RAG = @{
    Name = "RAG"
    RepoUrl = "https://github.com/Yrong-z/rag-knowledge-agent.git"
    Version = "v1.0.0"
  }
  T2S = @{
    Name = "T2S"
    RepoUrl = "https://github.com/Yrong-z/text2sql-data-agent.git"
    Version = "v1.0.1"
  }
}
