#encoding: utf-8

class StudiesController < ApplicationController
  load_and_authorize_resource
  
  def index
    @studies = Study.all :order => 'name'
  end

  def new
    @study = Study.new
  end

  def edit
  
  end

  def create
    @study = Study.new(params[:study])

    if @study.save
      redirect_to(studies_path, :notice => 'Der Studiengang wurde angelegt.') 
    else
      render :action => "new"
    end
  end

  def update
    if @study.update_attributes(params[:study])
      redirect_to(studies_path, :notice => 'Der Studiengang wurde geändert') 
    else
      render :action => "edit"
    end
  end

  def destroy
    if @study.users.count > 0
      redirect_to(studies_url, :notice => "Der Studiengang kann nicht gelöscht werden, da User mit diesem Studiengang existieren.") 
    else
      @study.destroy
      redirect_to studies_url, :notice => "Der Studiengang wurde entfernt"
    end
  end
end
