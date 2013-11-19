$ ->
  
  
  $('.send-message').click ->
    data = $('#user_search').serialize() + '&' + $.param({message: {to: $('#modal').attr('data-mode'), subject: $('#message_subject').val(), text: $('#message_text').val()}})
    url = $('#modal').attr('data-url')
    $.post url, data, (data) ->
      $('#modal').modal('hide')    
      # inform user
      $('.flash').html('<div class="alert"><a class="close" data-dismiss="alert" href="#">x</a>'+data['message']+'</div>')
      $('#queuecount').html(data['new_queue_count'])     
    false


    	
  $('.open-modal').click ->
    # set mode, message send url, recipient description
    $('#modal').attr('data-mode', $(this).attr('data-mode')) 
    $('#modal').attr('data-url', $(this).attr('data-url')) 
    $('#modal .recipients').text $(this).attr('data-to')
    $('#modal #message_subject').val $(this).attr('data-subject')
    $('#modal').modal('show')    
    false

  
  $('.insert-reminder-text').click ->
    $('#message_subject').val $('#reminder_header').val()    
    $('#message_text').val $('#reminder_text').val()
    false
  
