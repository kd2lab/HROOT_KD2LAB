# encoding: utf-8

class SessionGroupsController < ApplicationController
  load_and_authorize_resource :experiment
  
  def create
    SessionGroup.create(:experiment => @experiment, :signup_mode => SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP)
    redirect_to experiment_sessions_path(@experiment)
  end

end
