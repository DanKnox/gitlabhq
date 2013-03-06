class GollumWiki

  class CouldNotCreateWikiError < StandardError; end

  attr_reader :error_message

  def initialize(project, user = nil)
    @project = project
    @user = user
  end

  def wiki
    @wiki ||= begin
      Gollum::Wiki.new(path_to_repo)
    rescue Grit::NoSuchPathError
      create_repo!
    end
  end

  def pages
    wiki.pages.map { |page| WikiPage.new(self, page, true) }
  end

  def find_page(title, version = nil)
    if page = wiki.page(title, version)
      WikiPage.new(self, page, true)
    else
      nil
    end
  end

  def create_page(title, content)
    message = "#{@user.username} created page: #{title}"
    wiki.write_page(title, :markdown, content, commit_details(message))
  rescue Gollum::DuplicatePageError => e
    @error_message = "Duplicate page: #{e.message}"
    return false
  end

  def update_page(page, content)
    message = "#{@user.username} updated page: #{page.title}"
    wiki.update_page(page, page.name, :markdown, content, commit_details(message))
  end

  def delete_page(page)
    message = "#{@user.username} deleted page: #{page.title}"
    wiki.delete_page(page, commit_details(message))
  end

  private

  def create_repo!
    if gitlab_shell.add_repository(path_with_namespace)
      Gollum::Wiki.new(path_to_repo)
    else
      raise CouldNotCreateWikiError
    end
  end

  def commit_details(message = '')
    {email: @user.email, name: @user.name, message: message}
  end

  def path_with_namespace
    @project.path_with_namespace + ".wiki"
  end

  def gitlab_shell
    @gitlab_shell ||= Gitlab::Shell.new
  end

  def path_to_repo
    @path_to_repo ||= File.join(Gitlab.config.gitlab_shell.repos_path, "#{path_with_namespace}.git")
  end

end
