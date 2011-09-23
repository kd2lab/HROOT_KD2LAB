module ApplicationHelper
  def sortable(column, title = nil)  
    title ||= column.titleize  
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil  
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"  
    link_to title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class}  
  end
  
  def sortable_for_form(column, title = nil)  
    title ||= column.titleize  
    css_class = (column == sort_column) ? "sort-link current #{sort_direction}" : "sort-link"  
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"  
    link_to title, '', {:href => column, :'data-sort-direction' => direction, :class => css_class}  
  end
  
end
