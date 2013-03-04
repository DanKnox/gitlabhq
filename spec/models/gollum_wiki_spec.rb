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
  end

  describe "#pages" do
    before do
      create_page("index", "This is an awesome new Gollum Wiki")
      @pages = subject.pages
    end

    after do
      destroy_page(@pages.first)
    end

    it "returns an array of Gollum::Page instances" do
      @pages.first.should be_a Gollum::Page
    end

    it "returns the correct number of pages" do
      @pages.count.should == 1
    end
  end

  describe "#find_page" do
    before do
      create_page("index", "This is an awesome Gollum Wiki")
    end

    after do
      destroy_page(subject.pages.first)
    end

    it "returns the latest version of the page if it exists" do
      page = subject.find_page("index")
      page.name.should == "index"
    end

    it "returns nil if the page does not exist" do
      subject.find_page("non-existant").should == nil
    end
  end

  describe "#create_page" do
    after do
      destroy_page(subject.pages.first)
    end

    it "creates a new wiki page" do
      subject.create_page("test page", "this is content").should_not == false
      page = subject.find_page("test page")
      page.title.should == "test page"
      page.raw_data.should == "this is content"
    end

    it "returns false when a duplicate page exists" do
      subject.create_page("test page", "content")
      subject.create_page("test page", "content").should == false
    end

    it "stores an error message when a duplicate page exists" do
      subject.create_page("test page", "content")
      subject.create_page("test page", "content")
      subject.error_message.should =~ /Duplicate page:/
    end
  end

  describe "#delete_page" do
    before do
      create_page("index", "some content")
    end

    it "deletes the page" do
      subject.delete_page("index")
      subject.pages.count.should == 0
    end
  end

  describe "#history" do
    before do
      create_page("index", "some content")
    end

    it "returns an array of all commits for the page" do
      page = subject.find_page("index")
      history = page.versions
      history.count.should == 1
    end
  end

end
