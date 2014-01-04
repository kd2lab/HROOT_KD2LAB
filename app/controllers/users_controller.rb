#encoding: utf-8

class UsersController < ApplicationController
  load_and_authorize_resource
  
  helper_method :sort_column, :sort_direction
  
  def index
    params[:search] = params[:search] || Settings.standard_search || {}

    if params[:user_action] == "store_search"
      Settings.standard_search = params[:search]
      flash.now[:notice] = t('controllers.users.notice_search_stored')
    end
    
    @users = Search.paginate(params, {:sort_column => sort_column, :sort_direction => sort_direction})
    @user_count = User.count
  end

  def store_search
    params[:search] = params[:search] ||  {}
    Settings.standard_search = params[:search]

    redirect_to users_path, :notice => t('controllers.users.notice_search_stored')
  end
  
  def show
   
  end
  
  def remove_from_session
    if params[:session_id] && session = Session.find(params[:session_id])
      Session.remove_members_from_sessions([@user.id], session.experiment)
    end
    
    redirect_to user_path, :notice => t('controllers.users.notice_removed_from_session')
  end
    
  def new
    @user = User.new
    @user.role = "user"
  end

  def edit
    unless params[:privileges]
      params[:privileges] = []

      @user.experimenter_assignments.each do |assign|
        params[:privileges] << {:id => assign.experiment_id, :name => assign.experiment.name, :list => assign.rights.split(',')}
      end
    end
  end

  def create_user
    @user = User.new(params[:user])
    @user.skip_confirmation!
    @user.admin_update = true
    
    if @user.save
      redirect_to users_url, :notice => t('controllers.users.notice_created_user')
    else
      render :action => "new" 
    end
  end

  def update
    if params["user"]["password"].blank?
      params["user"].delete("password")
      params["user"].delete("password_confirmation")
    end

    params[:privileges] = [] unless params[:privileges]
      
    @user.admin_update = true  

    if @user.update_attributes(params[:user])
      ExperimenterAssignment.update_user_rights @user, params[:privileges]
      


      redirect_to user_url(@user), :notice => t('controllers.notice_saved_changes') 
    else
      render :edit
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
    redirect_to user_url(@user), :notice => t('controllers.users.notice_activated_after_import')
  end
  
  def login_as
    sign_in @user
    redirect_to account_path
  end
  
  def send_message
    if (params[:message][:to] == 'all')
      ids =  Search.search_ids(params[:search] || {})
    elsif (params[:message][:to] == 'selected')
      ids = params['selected_users'].keys.map(&:to_i)
    end  
    
    Message.send_message(current_user.id, ids, nil, params[:message][:subject], params[:message][:text])
    render :json => {:updated => ids.length, :new_queue_count => Recipient.where('sent_at IS NULL').count, :message => t('controllers.users.notice_mailqueue')}
  end
  
  def print
    params[:search] = params[:search] || Settings.standard_search || {}
    @users = Search.search(params[:search], {:sort_column => sort_column, :sort_direction => sort_direction})
    render :action => 'print', :layout => 'print'
  end

  def csv
    params[:search] = params[:search] || Settings.standard_search || {}
    users = Search.search(params[:search], {:sort_column => sort_column, :sort_direction => sort_direction})

    data = Exporter.to_csv(users, Rails.configuration.user_table_csv_columns)

    send_data(data, :type => 'text/csv', :filename => 'users.csv')
  end

  def excel
    params[:search] = params[:search] || Settings.standard_search || {}
    users = Search.search(params[:search], {:sort_column => sort_column, :sort_direction => sort_direction})

    data = Exporter.to_excel(users, Rails.configuration.user_table_csv_columns)

    send_data(data, :type => 'application/vnd.ms-excel', :filename => 'users.xls')
  end


  private

  def sort_column
    (User.column_names+['noshow_count', 'study_name', 'begin_date', 'participations_count']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
