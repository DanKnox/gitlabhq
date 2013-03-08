class WikisController < ProjectResourceController
  before_filter :authorize_read_wiki!
  before_filter :authorize_write_wiki!, only: [:edit, :create, :history]
  before_filter :authorize_admin_wiki!, only: :destroy
  before_filter :load_gollum_wiki

  def pages
    @wiki_pages = @gollum_wiki.pages
  end

  def show
    if params[:version_id]
      @wiki = @gollum_wiki.find_page(params[:id], params[:version_id])
    else
      @wiki = @gollum_wiki.find_page(params[:id])
    end

    if @wiki
      render 'show'
    else
      if can?(current_user, :write_wiki, @project)
        @wiki = WikiPage.new(@gollum_wiki)
        @wiki.title = params[:id]
        render 'edit'
      else
        render 'empty'
      end
    end
  end

  def edit
    @wiki = @gollum_wiki.find_page(params[:id])
  end

  def update
    @wiki = @gollum_wiki.find_page(params[:id])

    return render('empty') unless can?(current_user, :write_wiki, @project)

    if @wiki.update(content, format, message)
      redirect_to [@project, @wiki], notice: 'Wiki was successfully updated.'
    else
      render 'edit'
    end
  end

  def create
    @wiki = WikiPage.new(@gollum_wiki)

    respond_to do |format|
      if @wiki.create(wiki_params)
        format.thml { redirect_to [@project, @wiki], notice: 'Wiki was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def history
    respond_to do |format|
      if @wiki = @gollum_wiki.find_page(params[:id])
        format.html { @versions = @wiki.versions }
      else
        format.html { redirect_to project_wiki_path(@project, :index), notice: "Page not found" }
      end
    end
  end

  def destroy
    @wiki = @gollum_wiki.find_page(params[:id])
    @wiki.delete if @wiki

    respond_to do |format|
      format.html { redirect_to project_wiki_path(@project, :index), notice: "Page was successfully deleted" }
    end
  end

  private

  def load_gollum_wiki
    @gollum_wiki = GollumWiki.new(@project, current_user)
  end

  def wiki_params
    params[:wiki].slice(:title, :content, :format, :message)
  end

  def content
    params[:wiki][:content]
  end

  def format
    params[:wiki][:format]
  end

  def message
    params[:wiki][:message]
  end

end
