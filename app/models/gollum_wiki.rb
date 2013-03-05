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
    wiki.pages.map { |page| Page.new(page) }
  end

  def find_page(title)
    if page = wiki.paged(title)
      Page.new(page)
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

  def delete_page(title)
    message = "#{@user.username} deleted page: #{title}"
    page = find_page(title)
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

  class Page < Delegator

    def initialize(page)
      super
      @page = page
    end

    def __getobj__
      @page
    end

    def __setobj__(obj)
      @page = obj
    end

    def to_param
      @page.name
    end

  end

end
