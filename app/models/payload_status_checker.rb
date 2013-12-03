class PayloadStatusChecker
  STATUS_DESCRIPTIONS = {
    'success' => 'All contributors have signed the Contributor License Agreement.',
    'failure' => 'Not all contributors have signed the Contributor License Agreement.'
  }

  def initialize(payload)
    @payload = payload
  end

  def check_and_update
    Rails.logger.info("PayloadStatusChecker#check_and_update for payload #{@payload.user_name}/#{@payload.repo_name}:#{@payload.commits.map(&:id).join(',')}")
    return unless repo_agreement

    @payload.commits.each do |commit|
      check_commit(commit)
    end
  end

  private

  # TODO: extract a CommitStatusChecker
  def check_commit(commit)
    contributors = commit_contributors(commit)
    all_contributors_signed = contributors.all? { |contributor| signed_agreement?(contributor) }

    if all_contributors_signed
      mark(commit, 'success')
    else
      mark(commit, 'failure')
    end
  end

  def mark(commit, state)
    target_url = "#{HOST}/agreements/#{@payload.user_name}/#{@payload.repo_name}"

    GithubRepos.new(repo_agreement.user).set_status(@payload.user_name, @payload.repo_name, sha = commit.id, {
      state: state,
      target_url: target_url,
      description: STATUS_DESCRIPTIONS[state]
    })
  end

  def commit_contributors(commit)
    author_email = commit.author.try(:email)
    author_username = commit.author.try(:username)
    author = User.find_by_email_or_nickname(author_email, author_username)
    contributors = [author]

    if commit.committer
      committer_email = commit.committer.try(:email)
      committer_username = commit.committer.try(:username)
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

  def repo_agreement
    @repo_agreement ||= Agreement.where({
      user_name: @payload.user_name,
      repo_name: @payload.repo_name
    }).first
  end
end
