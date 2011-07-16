require 'rubygems'

class AdminController < ApplicationController
  access_control do   
    allow :admin
  end


  def index
  end

  def options
  end

  def users
  end

end
