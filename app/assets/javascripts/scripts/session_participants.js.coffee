$ ->   
  update_checkboxes = ->
    $('#all_show').attr('checked', $('.show_checkbox:not(:checked)').size() == 0)
    $('#all_participation').attr('checked', $('.participation_checkbox:not(:checked)').size() == 0)
    $('#all_noshow').attr('checked', $('.noshow_checkbox:not(:checked)').size() == 0)

  
  $('body').on 'click', '.show_checkbox', ->
    if $(this).is(':checked')
      $('.noshow_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
    else
      $('.participation_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false) 
    update_checkboxes()
      
  $('body').on 'click', '.noshow_checkbox', ->
    if $(this).is(':checked')
      $('.show_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
      $('.participation_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
    update_checkboxes()
      
  $('body').on 'click', '.participation_checkbox', ->
    if $(this).is(':checked')
      $('.show_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', true)
      $('.noshow_checkbox[data-id='+$(this).attr('data-id')+']').attr('checked', false)
    update_checkboxes()

  
  update_checkboxes()
  $('#all_show').click ->
    if $(this).is(':checked')      
      $('.show_checkbox').attr('checked', true)
      $('.noshow_checkbox').attr('checked', false)
    else
      $('.show_checkbox').attr('checked', false)
      $('.participation_checkbox').attr('checked', false)
    update_checkboxes()
    
  $('#all_participation').click ->
    if $(this).is(':checked')
    #  $('#all_show').attr('checked', true)
      $('.show_checkbox').attr('checked', true)
      $('.participation_checkbox').attr('checked', true)
      $('.noshow_checkbox').attr('checked', false)
    else
      $('.participation_checkbox').attr('checked', false)
    update_checkboxes()
      
  $('#all_noshow').click ->
    if $(this).is(':checked')
      $('.show_checkbox').attr('checked', false)
      $('.participation_checkbox').attr('checked', false)
      $('.noshow_checkbox').attr('checked', true)
    else
      $('.participation_checkbox').attr('checked', false)
    update_checkboxes()
    
  
  
