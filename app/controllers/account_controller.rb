# encoding: utf-8

class AccountController < ApplicationController
  authorize_resource :class => false
    
  # todo remove
  def index
    params[:session] = {} unless params[:session]
  end
  
  
  
end
