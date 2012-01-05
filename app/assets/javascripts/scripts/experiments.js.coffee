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
    
  # close button on filters and reopen
  $('a.close-link').click ->
    $($(this).attr('href')).fadeOut()
    $("input[id=active_#{$(this).attr('href').substring(1)}]").val("")
    false

  $('a.open-link').click ->
    $($(this).attr('href')).fadeIn()
    $("input[id=active_#{$(this).attr('href').substring(1)}]").val("1")
    false

  # add and remove buttons for experiment type
  $('a.add-link').click ->
    i = parseInt $('#exp_typ_count').val()
    if i < 10
       $('#exp_filter_'+i).fadeIn()
       $('#exp_typ_count').val i+1
    false

  $('a.remove-link').click ->
    i = parseInt $('#exp_typ_count').val()-1
    if i > 0
       $('#exp_filter_'+i).fadeOut()
       $('#exp_typ_count').val i
    false

  # ajax for enabling and disabling of experiment enrollment
  $('#state_button_enable').live 'click', ->
    $("#state").load "/admin/experiments/"+$(this).attr("data-id")+"/enable"
    
  $('#state_button_disable').live 'click', ->
    $("#state").load "/admin/experiments/"+$(this).attr("data-id")+"/disable"