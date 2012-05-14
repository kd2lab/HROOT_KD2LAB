class AdminController < ApplicationController
  authorize_resource :class => false
  
  def index
    
  end
  
  def calendar
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
        render :partial => "shared/text_templates_items", :locals => {:data => current_user.settings.templates, :element_id => params['element_id']}
      elsif params['mode'] == 'load'
        render :text => current_user.settings.templates[params['templatename']]
      elsif params['mode'] == 'delete'
        current_user.settings.templates = current_user.settings.templates.reject{|key| key == params['templatename']}
        render :partial => "shared/text_templates_items", :locals => {:data => current_user.settings.templates, :element_id => params['element_id']}
      end
    end
  end
  
end
