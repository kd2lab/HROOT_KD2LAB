#encoding: utf-8

class UsersController < ApplicationController
  load_and_authorize_resource
  
  helper_method :sort_column, :sort_direction
  
  def index
    # filters are only in session, when message was sent
    if session[:filter]
      params[:filter] = session[:filter]
      session[:filter] = nil
    end
    
    params[:filter] = params[:filter] || {}

    if params[:message] && params[:message][:action] == 'send'
      message = Message.create(
        :sender_id => current_user.id,
        :experiment_id => nil,
        :subject => params[:message][:subject],
        :message =>  params[:message][:text]
      )
      
      if (params[:message][:mode] == 'all')
        ids =  User.load_ids(params, {:sort_column => sort_column, :sort_direction => sort_direction})
      elsif (params[:message][:mode] == 'selected')
        ids = params['selected_users'].keys.map(&:to_i)
      end  
      
      Recipient.insert_bulk(message, ids)
      
      # store filters in session to enable redirect
      session[:filter] = params[:filter]
      redirect_to(users_path, :flash => {:notice => "Nachricht(en) wurden in die Mailqueue eingetragen."})
    end  
    
    @users = User.paginate(params, {:sort_column => sort_column, :sort_direction => sort_direction, :include_deleted_users => 1})
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
      redirect_to(user_url(@user), :notice => 'Der Benutzer wurde erfolgreich geändert') 
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
    (User.column_names+['noshow_count', 'study_name', 'begin_date', 'participations_count']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
