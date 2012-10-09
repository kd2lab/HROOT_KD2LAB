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
      redirect_to studies_path, :notice => t('controllers.study.notice_study_created')  
    else
      render :action => "new"
    end
  end

  def update
    if @study.update_attributes(params[:study])
      redirect_to studies_path, :notice => t('controllers.study.notice_study_changed')
    else
      render :action => "edit"
    end
  end

  def destroy
    if @study.users.count > 0
      redirect_to studies_url, :notice => t('controllers.study.notice_study_not_deleted')
    else
      @study.destroy
      redirect_to studies_url, :notice => t('controllers.study.notice_study_deleted')
    end
  end
end
