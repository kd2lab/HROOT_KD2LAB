# encoding: utf-8

class SessionGroupsController < ApplicationController
  # authorize_resource :class => false
  load_and_authorize_resource :experiment
  load_and_authorize_resource :session, :through => :experiment

  def index 

  end

end
