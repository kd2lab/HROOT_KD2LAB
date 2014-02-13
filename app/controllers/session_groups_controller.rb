# encoding: utf-8

class SessionGroupsController < ApplicationController
  load_and_authorize_resource :experiment
  
  def create
    SessionGroup.create(:experiment => @experiment)
    redirect_to experiment_sessions_path(@experiment)
  end

end
