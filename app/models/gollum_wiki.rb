class GollumWiki

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
    wiki.pages
  end

  def find_page(title)
    wiki.page(title)
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
    shell.add_repository(path_with_namespace)
    Gollum::Wiki.new(path_to_repo)
  end

  def commit_details(message = '')
    {email: @user.email, name: @user.name, message: message}
  end

  def path_with_namespace
    @project.path_with_namespace + ".wiki"
  end

  def shell
    @shell ||= Gitlab::Shell.new
  end

  def path_to_repo
    @path_to_repo ||= File.join(Gitlab.config.gitlab_shell.repos_path, "#{path_with_namespace}.git")
  end

end
