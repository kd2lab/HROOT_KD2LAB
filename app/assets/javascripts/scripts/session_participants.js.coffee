$ ->   
  update_checkboxes = ->
    $('#all_show').prop('checked', $('.show_checkbox:not(:checked)').size() == 0)
    $('#all_participation').prop('checked', $('.participation_checkbox:not(:checked)').size() == 0)
    $('#all_noshow').prop('checked', $('.noshow_checkbox:not(:checked)').size() == 0)

  
  $('body').on 'click', '.show_checkbox', ->
    if $(this).is(':checked')
      $('.noshow_checkbox[data-id='+$(this).attr('data-id')+']').prop('checked', false)
    else
      $('.participation_checkbox[data-id='+$(this).attr('data-id')+']').prop('checked', false) 
    update_checkboxes()
      
  $('body').on 'click', '.noshow_checkbox', ->
    if $(this).is(':checked')
      $('.show_checkbox[data-id='+$(this).attr('data-id')+']').prop('checked', false)
      $('.participation_checkbox[data-id='+$(this).attr('data-id')+']').prop('checked', false)
    update_checkboxes()
      
  $('body').on 'click', '.participation_checkbox', ->
    if $(this).is(':checked')
      $('.show_checkbox[data-id='+$(this).attr('data-id')+']').prop('checked', true)
      $('.noshow_checkbox[data-id='+$(this).attr('data-id')+']').prop('checked', false)
    update_checkboxes()

  
  update_checkboxes()
  
  $('#all_show').click ->
    if $(this).prop('checked')
      # add all show checkboxes
      $('.show_checkbox').prop('checked', true)
      $('.noshow_checkbox').prop('checked', false)
    else
      # remove every checked box
      $('.show_checkbox').prop('checked', false)
      $('.participation_checkbox').prop('checked', false)
      $('.noshow_checkbox').prop('checked', false)
    update_checkboxes()  
        
  $('#all_participation').click ->
    if $(this).prop('checked')
      # add all show and participated checkboxes
      $('.show_checkbox').prop('checked', true)
      $('.participation_checkbox').prop('checked', true)
      $('.noshow_checkbox').prop('checked', false)
    else
      $('.participation_checkbox').prop('checked', false)
      $('.noshow_checkbox').prop('checked', false)
    update_checkboxes()
      
  $('#all_noshow').click ->
    if $(this).is(':checked')
      $('.show_checkbox').prop('checked', false)
      $('.participation_checkbox').prop('checked', false)
      $('.noshow_checkbox').prop('checked', true)
    else
      $('.show_checkbox').prop('checked', false)
      $('.participation_checkbox').prop('checked', false)
      $('.noshow_checkbox').prop('checked', false)
    update_checkboxes()
    
  
  
