class WikiPage

  include ActiveModel::Validations

  # The Gitlab GollumWiki instance
  attr_reader :wiki

  # The raw Gollum Page instance
  attr_reader :page

  attr_reader :attributes

  def initialize(wiki, page = nil, persisted = false)
    @wiki = wiki
    @page = page
    @persisted = persisted
    @attributes = {}
    set_attributes if persisted?
  end

  # The escaped URL path of the page
  def slug
    @attributes[:slug]
  end

  # The formatted title of the page
  def title
    @attributes[:title]
  end

  def content
    @attributes[:content]
  end

  def save
  end

  def persisted?
    @persisted
  end

  private

  def set_attributes
    attributes[:slug] = @page.escaped_url_path
    attributes[:title] = @page.title
    attributes[:content] = @page.formatted_data
  end

end
