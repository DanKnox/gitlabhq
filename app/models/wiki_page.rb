class WikiPage

  def self.model_name
    @_model_name ||= ActiveModel::Name.new(self, Project, "wiki")
  end

  def self.param_key
    "wiki"
  end

  def self.route_key
    "title"
  end

  extend ActiveModel::Naming
  include ActiveModel::Validations

  validates :title, presence: true
  validates :content, presence: true

  # The Gitlab GollumWiki instance.
  attr_reader :wiki

  # The raw Gollum::Page instance.
  attr_reader :page

  # The attributes Hash used for storing and validating
  # new Page values before writing to the Gollum repository.
  attr_accessor :attributes

  def initialize(wiki, page = nil, persisted = false)
    @wiki = wiki
    @page = page
    @persisted = persisted
    @attributes = {}.with_indifferent_access
    set_attributes if persisted?
  end

  # The escaped URL path of this page.
  def slug
    @attributes[:slug]
  end

  alias :to_param :slug

  # The formatted title of this page.
  def title
    @attributes[:title] || ""
  end

  # Sets the title of this page.
  def title=(new_title)
    @attributes[:title] = new_title
  end

  # The raw content of this page.
  def content
    @attributes[:content]
  end

  # The processed/formatted content of this page.
  def formatted_content
    @attributes[:formatted_content]
  end

  # The markup format for the page.
  def format
    @attributes[:format] || :markdown
  end

  # The Grit::Commit instance for this page.
  def version
    @attributes[:version]
  end

  # The commit message for this page version
  def message
    version.try(:message)
  end

  def version
    return nil unless persisted?

    @version ||= Commit.new(@page.version)
  end

  def versions
    return [] unless persisted?

    @page.versions.map { |v| Commit.new(v) }
  end

  def created_at
    @page.version.date
  end

  def historical?
    @page.historical?
  end

  def persisted?
    @persisted == true
  end

  def to_key
    [:title]
  end

  def create(attr = {})
    @attributes.merge!(attr)

    save :create_page, title, content, format, message
  end

  def update(new_content = "", format = :markdown, message = nil)
    @attributes[:content] = new_content
    @attributes[:format] = format

    save :update_page, @page, content, format, message
  end

  def delete
    if wiki.delete_page(@page)
      true
    else
      false
    end
  end

  private

  def set_attributes
    attributes[:slug] = @page.escaped_url_path
    attributes[:title] = @page.title
    attributes[:content] = @page.raw_data
    attributes[:formatted_content] = @page.formatted_data
    attributes[:format] = @page.format
  end

  def save(method, *args)
    if valid? && wiki.send(method, *args)
      @page = wiki.wiki.paged(title)
      set_attributes
      @persisted = true
    else
      errors.add(:base, wiki.error_message) if wiki.error_message
      @persisted = false
    end
    @persisted
  end

end
