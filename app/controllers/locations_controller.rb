#encoding: utf-8

class LocationsController < ApplicationController
  load_and_authorize_resource
  add_breadcrumb :options, :options_path
  add_breadcrumb :index, :locations_path
  
  def index
    @locations = Location.all :order => 'name'
  end

  def new
    @location = Location.new
  end

  def edit
  
  end

  def create
    @location = Location.new(params[:location])

    if @location.save
      redirect_to(locations_path, :notice => t('controllers.location.notice_location_created')) 
    else
      render :action => "new"
    end
  end

  def update
    if @location.update_attributes(params[:location])
      redirect_to(locations_path, :notice => t('controllers.location.notice_location_changed')) 
    else
      render :action => "edit"
    end
  end

  def destroy
    if @location.sessions.count > 0
      redirect_to locations_url, :notice => t('controllers.location.notice_location_not_deleted')
    else
      @location.destroy
      redirect_to locations_url, :notice => t('controllers.location.notice_location_deleted')
    end
  end
end
