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
      redirect_to(languages_path, :notice => 'Die Sprache wurde angelegt.') 
    else
      render :action => "new"
    end
  end

  def update
    if @language.update_attributes(params[:language])
      redirect_to(languages_path, :notice => 'Die Sprache wurde geändert') 
    else
      render :action => "edit"
    end
  end

  def destroy
    @language.destroy
    redirect_to languages_url, :notice => "Die Sprache wurde entfernt"
  end
end
