module ParticipantsHelper
  def filter_style(class_name)
    params[:active][class_name] == "1" ? "" : "display:none"
  end
    
end
