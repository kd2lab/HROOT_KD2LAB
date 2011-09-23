class ParticipantsController < ApplicationController
  before_filter :load_experiment
  
  helper_method :sort_column, :sort_direction
  
  def index
    # destroy participation relation
    if (params[:submit_marked]) && params[:selected_users]
      params[:selected_users].keys.each do |id|
        p = Participation.find_by_user_id_and_experiment_id(id, @experiment.id)
        p.destroy if p
      end
      flash[:notice] = "Die Poolmitglieder wurden entfernt"
    end
    
    params[:active] = {} unless params[:active]
    params[:active][:frole] = '1'
    params[:role] = 'user' 
    @users = User.load(params, sort_column, sort_direction, @experiment, {:exclude_non_participants => 1})
    @user_count = @experiment.participants.where(:deleted => false, :role => 'user').count
  end
  
  def manage
    # create participation relation
    if (params[:submit_marked]) && params[:selected_users]
      params[:selected_users].keys.each do |id|
        p = Participation.find_or_create_by_user_id_and_experiment_id(id, @experiment.id)
      end
      flash[:notice] = "Die Poolmitglieder wurden zugeordnet"
    end  
    
    params[:active] = {} unless params[:active]
    params[:active][:frole] = '1'
    params[:role] = 'user' 
    @users = User.load(params, sort_column, sort_direction, @experiment, {:exclude_experiment_participants => 1})
    
    @user_count = User.where(:deleted => false, :role => 'user').count
    @participants_count = @experiment.participations.joins(:user).where('users.role' => 'user', 'users.deleted' => false).count
  end
  
  protected
  
  def load_experiment
    @experiment = Experiment.find_by_id(params[:experiment_id])
    if @experiment
      authorize! :all, @experiment
    else
      redirect_to root_url
    end
  end
  
  private

  def sort_column
    (User.column_names+['noshow_count', 'study_name', 'begin_date']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
