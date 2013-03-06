require "spec_helper"

describe GollumWiki do

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
    subject.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(page)
    subject.wiki.delete_page(page, commit_details)
  end

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:user) { project.owner }

  subject { GollumWiki.new(project, user) }

  before do
    create_temp_repo(subject.send(:path_to_repo))
  end

  describe "#wiki" do
    it "contains a Gollum::Wiki instance" do
      subject.wiki.should be_a Gollum::Wiki
    end

    before do
      Gitlab::Shell.any_instance.stub(:add_repository) do
        create_temp_repo("#{Rails.root}/tmp/test-git-base-path/non-existant.wiki.git")
      end
      project.stub(:path_with_namespace).and_return("non-existant")
    end

    it "creates a new wiki repo if one does not yet exist" do
      wiki = GollumWiki.new(project, user)
      wiki.create_page("index", "test content").should_not == false

      FileUtils.rm_rf wiki.send(:path_to_repo)
    end

    it "raises CouldNotCreateWikiError if it can't create the wiki repository" do
      Gitlab::Shell.any_instance.stub(:add_repository).and_return(false)
      expect { GollumWiki.new(project, user).wiki }.to raise_exception(GollumWiki::CouldNotCreateWikiError)
    end
  end

  describe "#pages" do
    before do
      create_page("index", "This is an awesome new Gollum Wiki")
      @pages = subject.pages
    end

    after do
      destroy_page(@pages.first.page)
    end

    it "returns an array of WikiPage instances" do
      @pages.first.should be_a WikiPage
    end

    it "returns the correct number of pages" do
      @pages.count.should == 1
    end
  end

  describe "#find_page" do
    before do
      create_page("index page", "This is an awesome Gollum Wiki")
    end

    after do
      destroy_page(subject.pages.first.page)
    end

    it "returns the latest version of the page if it exists" do
      page = subject.find_page("index page")
      page.title.should == "index page"
    end

    it "returns nil if the page does not exist" do
      subject.find_page("non-existant").should == nil
    end

    it "can find a page by slug" do
      page = subject.find_page("index-page")
      page.title.should == "index page"
    end

    it "returns a WikiPage instance" do
      page = subject.find_page("index page")
      page.should be_a WikiPage
    end
  end

  describe "#create_page" do
    after do
      destroy_page(subject.pages.first.page)
    end

    it "creates a new wiki page" do
      subject.create_page("test page", "this is content").should_not == false
      subject.pages.count.should == 1
    end

    it "returns false when a duplicate page exists" do
      subject.create_page("test page", "content")
      subject.create_page("test page", "content").should == false
    end

    it "stores an error message when a duplicate page exists" do
      2.times { subject.create_page("test page", "content") }
      subject.error_message.should =~ /Duplicate page:/
    end
  end

  describe "#update_page" do
    before do
      create_page("update-page", "some content")
      @page = subject.wiki.paged("update-page")
    end

    after do
      destroy_page(@page)
    end

    it "updates the content of the page" do
      subject.update_page(@page, "some other content")
      page = subject.wiki.paged("update-page")
      page.raw_data.should == "some other content"
    end
  end

  describe "#delete_page" do
    before do
      create_page("index", "some content")
      @page = subject.wiki.paged("index")
    end

    it "deletes the page" do
      subject.delete_page(@page)
      subject.pages.count.should == 0
    end
  end

end
