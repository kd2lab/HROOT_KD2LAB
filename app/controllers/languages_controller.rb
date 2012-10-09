#encoding: utf-8

class LanguagesController < ApplicationController
  load_and_authorize_resource
  
  def index
    @languages = Language.all :order => 'name'
  end

  def new
    @language = Language.new
  end

  def edit
  
  end

  def create
    @language = Language.new(params[:language])

    if @language.save
      redirect_to languages_path, :notice => t('controllers.language.notice_language_created') 
    else
      render :action => "new"
    end
  end

  def update
    if @language.update_attributes(params[:language])
      redirect_to languages_path, :notice => t('controllers.language.notice_language_changed')
    else
      render :action => "edit"
    end
  end

  def destroy
    @language.destroy
    redirect_to languages_url, :notice => t('controllers.language.notice_language_deleted')
  end
end
