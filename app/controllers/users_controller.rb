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
      if (params[:message][:mode] == 'all')
        ids =  User.load_ids(params, {:sort_column => sort_column, :sort_direction => sort_direction})
      elsif (params[:message][:mode] == 'selected')
        ids = params['selected_users'].keys.map(&:to_i)
      end  
      
      Message.send_message(current_user.id, ids, nil, params[:message][:subject], params[:message][:text])
      
      # store filters in session to enable redirect
      session[:filter] = params[:filter]
      redirect_to(users_path, :flash => {:notice => "Nachricht(en) wurden in die Mailqueue eingetragen."})
    elsif !params[:user_action].blank?  
      # store filters in session to enable redirect
      session[:filter] = params[:filter]
      
      if params[:user_action] == "invite_all"
        params[:filter] = params[:filter].merge({:activated_after_import => false, :role => 'user'})
        ids =  User.load_ids(params, {:sort_column => sort_column, :sort_direction => sort_direction})
      elsif params[:user_action] == "invite_selected"
        selected_ids = params['selected_users'].keys.map(&:to_i)
        ids = User.where('activated_after_import=0 AND deleted=0 AND role="user"').where("id IN (?)", selected_ids).map(&:id)
      end
      
      Message.send_message(current_user.id, ids, nil, Settings.import_invitation_subject, Settings.import_invitation_text)
      
      redirect_to(users_path, :flash => {:notice => "Die Aktivierungs-Einladungen(en) wurden in die Mailqueue eingetragen."})
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

  def create_user
    @user = User.new(params[:user])
    @user.skip_confirmation!
    @user.admin_update = true
    
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
  
  def activate_after_import
    @user.activated_after_import = true
    @user.import_token = nil
    @user.save
    redirect_to(user_url(@user), :notice => 'Der Benutzer wurde nach dem Import freigeschaltet.') 
  end
  
  def login_as
    sign_in @user
    redirect_to account_path
  end
  
  private

  def sort_column
    (User.column_names+['noshow_count', 'study_name', 'begin_date', 'participations_count']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
