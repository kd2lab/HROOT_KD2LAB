module UsersHelper
  def is_enabled(varname)
    return { 'data-enabled' => (params[:filter] && params[:filter].has_key?(varname)).to_s, :style => if params[:filter][varname].blank? then 'display:none' else '' end }
  end
    
  
end
