@reload = -> 
  i=60
  window.setTimeout 'location.reload()', 60000
  window.setInterval ( -> $('#time_info').html((--i))), 1000 

$ ->
      
    
  # ajax experiment list
  $('#experiments th a, #experiments .pagination a').live 'click', ->  
    $.getScript this.href
    false 
  
  # Search form.  
  $('#experiment_search').submit ->
    $.get this.action, $(this).serialize(), null, 'script'  
    false
    
  
  $('.accordion .toggle').hide();

  $('.accordion td h3').click ->
    $(this).parent().find('.toggle').slideToggle(200)
    $(this).parent().find('i').toggleClass('icon-chevron-right')
    $(this).parent().find('i').toggleClass('icon-chevron-down')
    

  # ajax for enabling and disabling of experiment enrollment
  $('#state_button_enable').live 'click', ->
    $("#state").load "/admin/experiments/"+$(this).attr("data-id")+"/enable"
    
  $('#state_button_disable').live 'click', ->
    $("#state").load "/admin/experiments/"+$(this).attr("data-id")+"/disable"


  check_form_enabling = ->
    if $('#reminder_check').attr('checked')
      $('.subpart').show()
    else
      $('.subpart').hide()
  
  check_form_enabling()
  
  # enabling / disabling the reminder
  $('#reminder_check').click ->
    check_form_enabling()