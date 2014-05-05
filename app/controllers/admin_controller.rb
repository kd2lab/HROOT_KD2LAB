class AdminController < ApplicationController
  authorize_resource :class => false, :except => :templates
  
  def index
    add_breadcrumb :index, :admin_index_path
    if current_user.admin?
      @next_sessions = Session.where('DATE(start_at) >= DATE(NOW())').order('start_at').limit(20).group_by{|s| s.experiment_id}
      @latest_experiments = Experiment.order('created_at DESC').limit(5)
      @incomplete_sessions = Session.incomplete_sessions.order(:start_at)
      
    else
      @next_sessions = Session.where('DATE(start_at) >= DATE(NOW())').where(['sessions.experiment_id IN (SELECT experiment_id FROM experimenter_assignments WHERE user_id = ?)', current_user.id]).order('start_at').limit(20).group_by{|s| s.experiment_id}
      @latest_experiments = Experiment.where(['id IN (SELECT experiment_id FROM experimenter_assignments WHERE user_id = ?)', current_user.id]).order('created_at DESC').limit(5)
      @incomplete_sessions = Session.incomplete_sessions.where(['sessions.experiment_id IN (SELECT experiment_id FROM experimenter_assignments WHERE user_id = ?)', current_user.id]).order(:start_at)
    
    end
    
  end
  
  def calendar
    add_breadcrumb :calendar, :calendar_path
    @month = (params[:month] || (Time.zone || Time).now.month).to_i
    @year = (params[:year] || (Time.zone || Time).now.year).to_i
    @shown_month = Date.civil(@year, @month)
    @event_strips = Session.event_strips_for_month(@shown_month, 1)
  end
  
  def templates
    current_user.settings.templates = {} unless current_user.settings.templates
    
    if request.xhr?
      if params['mode'] == 'create'
        current_user.settings.templates = current_user.settings.templates.merge({params['templatename'] => params['value']})
        render :partial => "shared/text_templates", :locals => {:data => current_user.settings.templates, :element_id => params['element_id']}
      elsif params['mode'] == 'load'
        text = current_user.settings.templates[params['templatename']]
        render :text => current_user.settings.templates[params['templatename']]
      elsif params['mode'] == 'delete'
        current_user.settings.templates = current_user.settings.templates.reject{|key| key == params['templatename']}
        render :partial => "shared/text_templates", :locals => {:data => current_user.settings.templates, :element_id => params['element_id']}
      end
    end
  end
  
  
end
