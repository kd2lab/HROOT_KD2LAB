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
      flash[:notice] = 'Es wurde Ihnen eine E-Mail zur Aktivierung Ihres Zugangs zugesandt.'
      
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

      flash[:notice] = 'Ihr Zugang wurde aktiviert'
      redirect_to account_url
    else
      flash[:notice] = 'Dieser Aktivierungscode ist ungültig'
      redirect_to login_url
    end
  end
end
