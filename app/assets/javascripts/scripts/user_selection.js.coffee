      
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

  # build a form and add search fields, post back (used for csv and print)
  $('.with_search').click ->
    form = $('<form />', { action:  $(this).attr('href'), method: 'post', style: 'display: none;', target: $(this).attr('target')})
    $('#user_search').serializeArray().forEach (o) ->
      $('<input />', {type: 'hidden', name: o.name, value: o.value}).appendTo(form)   
      
    form.appendTo('body').submit()
    false


  # Actions on user lists
  $('.user_action_link').click ->
    if $(this).attr('data-confirm') && !confirm($(this).attr('data-confirm'))
      return false
    
    $('#user_action_type').val($(this).attr('data-type'))
    $('#user_action_value').val($(this).attr('data-value'))
      
    $('#user_search').submit()
    false