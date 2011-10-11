#encoding: utf-8

class LocationsController < ApplicationController
  load_and_authorize_resource
  
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
      redirect_to(locations_path, :notice => 'Der Raum wurde angelegt.') 
    else
      render :action => "new"
    end
  end

  def update
    if @location.update_attributes(params[:location])
      redirect_to(locations_path, :notice => 'Der Raum wurde geändert') 
    else
      render :action => "edit"
    end
  end

  def destroy
    if @location.sessions.count > 0
      redirect_to(locations_url, :notice => "Der Raum kann nicht gelöscht werden, da Sessions für diesen Raum eingetragen sind.") 
    else
      @location.destroy
      redirect_to locations_url, :notice => "Der Raum wurde entfernt"
    end
  end
end
