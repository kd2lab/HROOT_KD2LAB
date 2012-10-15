$ ->
  # i18n
  send_text = $('#message_dialog').data('send-button')
  abort_text = $('#message_dialog').data('abort-button')
    
  dialog_values = 
    autoOpen: false
    modal: true
    width: 800
    height: 600
    buttons: {}
    create: -> 
      $(".ui-widget-header").hide()
      $('.ui-button').addClass('btn') 
      $('.ui-button:eq(0)').addClass('btn-primary').css('margin-right', '5px')
  
  dialog_values.buttons[send_text] = -> 
    $('#message_action').val('send')
    $('#user_search').submit()
    $( this ).dialog( "close" )
  
  dialog_values.buttons[abort_text] = -> 
    ($( this ).dialog( "close" ))
  
  
  $('#message_dialog').dialog(dialog_values)
  $("#message_dialog").parent().appendTo($("form:first"));
  
  $('.send-message').click ->
	  $('#message_dialog').dialog 'open'
	  $('#message_mode').val $(this).attr('data-mode')
	  $('#message_recipients').text $(this).attr('data-to')
	  $('#message_subject').val $(this).attr('data-subject')
	  false
	  
  $('.insert-reminder-text').click ->
    $('#message_subject').val $('#reminder_header').val()    
    $('#message_text').val $('#reminder_text').val()
    
	
	
