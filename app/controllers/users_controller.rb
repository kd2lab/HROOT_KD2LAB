class UsersController < ApplicationController
  load_and_authorize_resource
  
  helper_method :sort_column, :sort_direction
  
  def index
    @users = User.search(params[:search]).order(sort_column + ' ' + sort_direction).paginate(:per_page => 50, :page => params[:page])  
  end

  def show
    #@user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def edit
    #@user = User.find(params[:id])
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to(users_url, :notice => 'User was successfully created.') 
    else
      render :action => "new" 
    end
  end

  def update
    #@user = User.find(params[:id])
    
    if @user.update_attributes(params[:user])
      redirect_to(users_url :notice => 'User was successfully updated.') 
    else
      render :action => "edit" 
    end
  end

  def destroy
    #@user = User.find(params[:id])
    @user.destroy

    redirect_to(users_url) 
  end
  
  private

  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
