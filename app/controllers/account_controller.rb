# encoding: utf-8

class AccountController < ApplicationController
  authorize_resource :class => false
    
  def index
    params[:session] = {} unless params[:session]
  end
  
  def confirm
    # sanitize params
    params[:session] = {} unless params[:session]
    keys = params[:session].keys.map(&:to_i)
    @sessions = current_user.available_sessions.select{|s| keys.include?(s.id)}
  end
  
  def register
    # sanitize params
    params[:session] = {} unless params[:session]
    keys = params[:session].keys.map(&:to_i)
    @sessions = current_user.available_sessions.select{|s| keys.include?(s.id)}
    
    # register user for each session
    @sessions.each do |session|
      p = Participation.find_by_user_id_and_experiment_id(current_user.id, session.experiment_id)
      
      # store possible sessions for user
      p.commitments = [] unless p.commitments
      p.commitments << session.id
      
      # mark user as registered
      p.registered = true
      p.save
      
      # todo: check if this semantics is ok:
      # a user without session choice will get the experiment again
      # there is no successful registration with zero session
    end 
    
    redirect_to(account_path, :notice => 'Ihre möglichen Zeiten wurden gespeichert.')
  end
  
end
