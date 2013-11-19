      
$ ->
  # show or hide context menu
  check_menu = () ->
    if $('.user-selection-item:checked').size() > 0
      $('.context-menu').fadeIn('fast')
    else
      $('.context-menu').fadeOut('fast')

  # header checkbox of row selection
  $('.user-selection-header').click ->
    $('.user-selection-item').prop('checked', $(this).is(':checked'));
    check_menu()
    
  # item checkboxes of row selection  
  $('.user-selection-item').click ->
    $('.user-selection-header').prop('checked', $('.user-selection-item:not(:checked)').size() == 0)
    check_menu()

  # Actions on user lists
  $('.user_action_link').click ->
    if $(this).attr('data-confirm') && !confirm($(this).attr('data-confirm'))
      return false
    
    $('#user_action').val($(this).attr('data-value'))
    if $(this).attr('data-target')
      $('#user_search').attr("target", $(this).attr('data-target'))
      
    $('#user_search').submit()
    
    # reset form values again, so form can be submitted again
    $('#user_search').removeAttr("target")
    $('#user_action').val('')  
    return false