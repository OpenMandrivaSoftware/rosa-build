require 'base64'

module Project::GithubApi
  extend ActiveSupport::Concern

  def github_data
      Github.repos.get user: github_get_organization, repo: name rescue nil
  end

  def github_branches
      Github.repos.branches user: github_get_organization, repo: name rescue nil
  end

  def github_tags
      Github.repos.tags user: github_get_organization, repo: name rescue nil
  end

  def github_branch(branch_name)
    Github.repos.branch user: github_get_organization, repo: name, branch: branch_name rescue nil
  end

  def github_get_commit(hash)
    Github.repos.commits.list user: github_get_organization, repo: name, sha: hash rescue nil
  end

  def github_tree(hash)
    Github.git_data.trees.get user: github_get_organization, repo: name, sha: hash rescue nil
  end

  def find_blob_and_raw_of_spec_file(project_version)
    return unless branch = github_branch(project_version)
    commit_sha = branch.commit.sha
    return unless root_tree = github_tree(commit_sha)
    spec_file = root_tree.tree.select do |item|
      item.type=="blob" and item.path =~ /.spec$/
    end
    return if spec_file.empty?
    spec_file_sha = spec_file[0].sha
    blob_data = Github.git_data.blobs.get user: github_get_organization, repo: name, sha: spec_file_sha rescue return nil
    content = Base64.decode64(blob_data.content).gsub('\n', "\n")
    [spec_file_sha, content]
  end

  def update_file(path, data, options = {})
    
  end
  
  def github_get_organization
    return github_organization if github_organization.presence
    APP_CONFIG['github_organization']
  end
end