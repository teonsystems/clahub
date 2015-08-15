class CommitGroup
  STATUS_TYPES = {
    'success' => {
      'state' => 'success',
      'description' => 'All contributors have signed the Contributor License Agreement.',
    },
    'failure' => {
      'state' => 'failure',
      'description' => 'Not all contributors have signed the Contributor License Agreement.'
    },
    'ancestor_failure' => {
      'state' => 'failure',
      'description' => 'One or more of this commit\'s parents has contributors who have not signed the Contributor License Agreement.'
    }
  }

  def initialize(repo_owner_name, repo_name)
    @repo_owner_name = repo_owner_name
    @repo_name = repo_name
  end

  def check_and_update
    ids = @commits.map { |commit| commit["id"] }.join(",")
    Rails.logger.info(
      "PushStatusChecker#check_and_update for push #{@repo_owner_name}/#{@repo_name}:#{ids}")
    return unless repo_agreement

    @commits.reduce(false) do |ancestor_has_failed, commit|
      if ancestor_has_failed
        not mark(commit, 'ancestor_failure')
      else
        not check_commit(commit)
      end
    end
  end

  def fetch_from_pull_request(pull_request_number)
    @commits = github_repos.get_pull_commits(
        @repo_owner_name, @repo_name, pull_request_number
      ).map { |commit_hash|
          # TODO: Add test case for no author only committer on this phase
          commit = { id: commit_hash.sha }
          commit[:author] = { username: commit_hash.author.login } if commit_hash.author
          commit[:committer] = { username: commit_hash.committer.login } if commit_hash.committer
          Hashie::Mash.new(commit)
        }

    @commits
  end

  def set_from_payload(payload)
    @commits = payload.commits || []

    @commits
  end

  def length
    @commits && @commits.length || 0
  end

  private

  # TODO: extract a CommitStatusChecker
  def check_commit(commit)
    contributors = commit_contributors(commit)
    all_contributors_signed = contributors.all? { |contributor|
      signed = signed_agreement?(contributor)
      if contributor
        Rails.logger.info("check_commit for #{commit.id}: #{contributor.id} #{contributor.email}: #{signed}")
      else
        Rails.logger.info("check_commit for #{commit.id}: nil: #{signed}")
      end
      signed
    }

    if all_contributors_signed
      mark(commit, 'success')
    else
      mark(commit, 'failure')
    end
  end

  def mark(commit, status_name)
    target_url = "#{HOST}/agreements/#{@repo_owner_name}/#{@repo_name}"

    github_repos.set_status(@repo_owner_name, @repo_name, commit.id, {
      state: STATUS_TYPES[status_name]['state'],
      target_url: target_url,
      description: STATUS_TYPES[status_name]['description'],
      context: $CLAHUB_CONFIG['oauth_context_title']
    })

    STATUS_TYPES[status_name]['state'] == 'success'
  end

  def commit_contributors(commit)
    contributors = []

    if commit.author
      author_email = commit.author.email
      author_username = commit.author.username
      author = User.find_by_email_or_nickname(author_email, author_username)
      contributors << author
    end

    if commit.committer
      committer_email = commit.committer.email
      committer_username = commit.committer.username
      committer = User.find_by_email_or_nickname(committer_email, committer_username)
      contributors << committer
    end

    contributors
  end

  def signed_agreement?(candidate)
    return false if candidate.nil?

    Signature.exists?({
      user_id: candidate.id,
      agreement_id: repo_agreement.id
    })
  end

  def github_repos
    @github_repos ||= GithubRepos.new(repo_agreement.user)
  end

  # TODO: Move this logic into the `github_repos` method if it isn't needed
  # elsewhere.
  def repo_agreement
    @repo_agreement ||= Agreement.where({
      user_name: @repo_owner_name,
      repo_name: @repo_name
    }).first
  end
end
