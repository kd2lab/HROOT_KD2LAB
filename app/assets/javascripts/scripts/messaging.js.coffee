$ ->
	$('#message_dialog').dialog(autoOpen: false,
    modal: true
    width: 800
    height: 730
    buttons: {
      "Nachrichten senden": -> 
        $('#message_action').val('send')
        $('#user_search').submit()
        $( this ).dialog( "close" )
      "Abbrechen": -> ($( this ).dialog( "close" ))	
    }
    create: -> 
      $(".ui-widget-header").hide()
      $('.ui-button').addClass('btn') 
      $('.ui-button:eq(0)').addClass('btn-primary').css('margin-right', '5px') 
  )     
  $("#message_dialog").parent().appendTo($("form:first"));

  $('.send-message').click ->
	  $('#message_dialog').dialog 'open'
	  $('#message_mode').val $(this).attr('data-mode')
	  $('#message_recipients').text $(this).attr('data-to')
	  $('#message_subject').val $(this).attr('data-subject')
	  false
	  

	
	
