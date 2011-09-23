#encoding: utf-8

class UsersController < ApplicationController
  load_and_authorize_resource
  
  helper_method :sort_column, :sort_direction
  
  def index
    params[:active] = {} unless params[:active]
     
    @users = User.load(params, sort_column, sort_direction, nil, {:include_deleted_users => 1})
    @user_count = User.count
  end

  def show
   
  end

  def new
    @user = User.new
    @user.role = "user"
  end

  def edit
  
  end

  def create
    @user = User.new(params[:user])
    @user.skip_confirmation!
    if @user.save
      redirect_to(users_url, :notice => 'Der Benutzer wurde erfolgreich angelegt.') 
    else
      render :action => "new" 
    end
  end

  def update
    if params["user"]["password"].blank?
      params["user"].delete("password")
      params["user"].delete("password_confirmation")
    end
      
    if @user.update_attributes(params[:user])
      redirect_to(users_url, :notice => 'Der Benutzer wurde erfolgreich geändert') 
    else
      render :action => "edit" 
    end
  end

  def destroy
    @user.destroy

    redirect_to(users_url) 
  end
  
  private

  def sort_column
    (User.column_names+['noshow_count', 'study_name', 'begin_date']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
