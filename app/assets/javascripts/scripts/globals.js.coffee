$ =>
  # ajax experiment list
  $('#experiments th a, #experiments .pagination a').live 'click', ->  
    $.getScript this.href
    false 
  
  # Search form.  
  $('#experiment_search').submit ->
    $.get this.action, $(this).serialize(), null, 'script'  
    false
  
  # activate chosen
  $(".chzn-select").chosen()
  
  # form change detection
  $(".guarded_form :input").change ->
    $(this).closest('form').data 'changed', true
    window.onbeforeunload = -> "Achtung: Die Änderungen wurden noch nicht gespeichert!"
  
  $('.guarded_form_save').click ->
    window.onbeforeunload = null
  
  
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
    
  # sorting of participants list
  $('a.sort-link').click ->
    $('#sort').val($(this).attr('href'))
    $('#direction').val($(this).attr 'data-sort-direction')
    $('form').submit()
    false
  
  
  # select and deselect all checkboxes
  $('a.all-link').click ->
    $('form input[type=checkbox]').attr 'checked', true
    false
  
  $('a.none-link').click ->
    $('form input[type=checkbox]').attr 'checked', false
    false
  
  # on submit of "all" check all boxes
  $('.submit_all').click ->
    $('form input[type=checkbox]').attr 'checked', true
    
    
  # add and remove url lines for settings
  $('a.add-url-link').click ->
    $('#url-tags').append('<span> ... <input id="mail_restrictions__prefix" name="mail_restrictions[][prefix]" type="text" value="" /> ... @ '+
                          '<input id="mail_restrictions__suffix" name="mail_restrictions[][suffix]" type="text" value="" /><br/></span>')
                
  $('a.remove-url-link').click ->
    $('#url-tags span:last-child').remove()