# Encoding: UTF-8

class UsersController < ApplicationController
  before_filter :require_no_user
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    if @user.save_without_session_maintenance
      flash[:notice] = nil
      @user.deliver_activation_instructions!
      flash[:notice] = 'Es wurde Dir eine Mail zugesandt.'
      
      redirect_to root_url
    else
      render :action => "new"
    end
  end
  
  def activate
    @user = User.find_using_perishable_token(params[:activation_code])

    if @user
      @user.activate!

      # login user
      UserSession.create(@user)

      flash[:notice] = 'You activated your account'
      redirect_to account_url
    else
      flash[:notice] = 'There was no user for this activation code'
      redirect_to login_url
    end
  end
end
