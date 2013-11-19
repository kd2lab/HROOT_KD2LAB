@reload = -> 
  i=60
  window.setTimeout 'location.reload()', 60000
  window.setInterval ( -> $('#time_info').html((--i))), 1000 

$ ->
        
  # Search form.  
  $('#experiment_search').submit ->
    $.get this.action, $(this).serialize(), null, 'script'  
    false
    
  
  $('.accordion .toggle').hide();

  $('.accordion td h4').click ->
    $(this).parent().find('.toggle').slideToggle(200)
    $(this).parent().find('i').toggleClass('icon-chevron-right')
    $(this).parent().find('i').toggleClass('icon-chevron-down')
    

  # ajax for enabling and disabling of experiment enrollment
  $('body').on 'click', '.state-button-enable',  ->
    $.get $(this).data('url'), (result)->
      $('.state').replaceWith(result)
    
  $('body').on 'click', '.state-button-disable',  ->
    $.get $(this).data('url'), (result)->
      $('.state').replaceWith(result)
  
  check_form_enabling = ->
    if $('#reminder_check').prop('checked')
      $('.subpart').show()
    else
      $('.subpart').hide()
  
  check_form_enabling()
  
  # enabling / disabling the reminder
  $('#reminder_check').click ->
    check_form_enabling()