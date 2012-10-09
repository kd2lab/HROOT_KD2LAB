#encoding: utf-8

class ProfessionsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @professions = Profession.all :order => 'name'
  end

  def new
    @profession = Profession.new
  end

  def edit
  
  end

  def create
    @profession = Profession.new(params[:profession])

    if @profession.save
      redirect_to professions_path, :notice => t('controllers.profession.notice_profession_created') 
    else
      render :action => "new"
    end
  end

  def update
    if @profession.update_attributes(params[:profession])
      redirect_to professions_path, :notice => t('controllers.profession.notice_profession_changed') 
    else
      render :action => "edit"
    end
  end

  def destroy
    if @profession.users.count > 0
      redirect_to professions_url, :notice => t('controllers.profession.notice_profession_not_deleted') 
    else
      @profession.destroy
      redirect_to professions_url, :notice => t('controllers.profession.notice_profession_deleted') 
    end
    
  end
end
