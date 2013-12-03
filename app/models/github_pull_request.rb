class GithubPullRequest
  def initialize(json)
    @mash = Hashie::Mash.new(JSON.parse(json))
  end

  def repo_name
    @mash.repository.try(:name)
  end

  def user_name
    @mash.repository.try(:owner).try(:name)
  end

  def commits
    [@mash.pull_request.head.sha]
  end
end
