require "spec_helper"

describe WikiPage do

  def create_temp_repo(path)
    FileUtils.mkdir_p path
    command = "git init --quiet #{path};"
    system(command)
  end

  def remove_temp_repo(path)
    FileUtils.rm_rf path
  end

  def commit_details
    commit = {name: user.name, email: user.email, message: "test commit"}
  end

  def create_page(name, content)
    wiki.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(page)
    wiki.wiki.delete_page(page, commit_details)
  end

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:user) { project.owner }
  let(:wiki) { GollumWiki.new(project, user) }

  subject { WikiPage.new(wiki) }

  before do
    create_temp_repo(wiki.send(:path_to_repo))
  end

  describe "#initialize" do
    context "when initialized with an existing gollum page" do
      before do
        create_page("test page", "test content")
        @page = wiki.wiki.paged("test page")
        @wiki_page = WikiPage.new(wiki, @page, true)
      end

      it "sets the slug attribute" do
        @wiki_page.slug.should == "test-page"
      end

      it "sets the title attribute" do
        @wiki_page.title.should == "test page"
      end

      it "sets the formatted content attribute" do
        @wiki_page.content.should == "<p>test content</p>"
      end
    end
  end

end
