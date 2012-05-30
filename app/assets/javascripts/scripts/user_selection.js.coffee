update_user_selection = ->
  $('#select_all_users').attr('checked', $('.selected_users:not(:checked)').size() == 0)
  if $('.selected_users:checked').size() > 0
    $('.context-menu').fadeIn('fast')
  else
    $('.context-menu').fadeOut('fast')
      
$ ->
  update_user_selection()
  
  $('.selected_users').click ->
    update_user_selection()
 
  $('#select_all_users').click ->
    if $(this).is(':checked')      
      $('.selected_users').attr('checked', true)
    else
      $('.selected_users').attr('checked', false)
    update_user_selection()