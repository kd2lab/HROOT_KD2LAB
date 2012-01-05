update_menu = ->
  if $('.selected_users:checked').size() > 0
    $('.move-menu').fadeIn('fast')
  else
    $('.move-menu').fadeOut('fast')
    

$ -> 
  $('.show_checkbox').click ->
    if $(this).is(':checked')
      $('.noshow_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
    else
      $('.participation_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
      
  $('.noshow_checkbox').click ->
    if $(this).is(':checked')
      $('.show_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
      $('.participation_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
      
  $('.participation_checkbox').click ->
    if $(this).is(':checked')
      $('.show_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', true)
      $('.noshow_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)

  $('#move-member').change ->
    $('form').submit()
    
  update_menu()
  $('.selected_users').click ->
    update_menu()
    
    
    