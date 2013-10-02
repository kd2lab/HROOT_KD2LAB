$ ->
  
  # activate timepicker
  $('.timepicker').timepicker()
  
  # activate datepicker js
  $('.datepicker').datepicker(
    language: $('body').data('locale') 
  )
        
  # activate chosen
  # todo clean this up
  
  $(".chzn-select-search").chosen({disable_search_threshold: 10, width: '400px'})
  $(".chzn-select-search-tags").chosen({width: '150px'})

  $(".chzn-select").chosen({width: '150px'})
  $(".chzn-select-register").chosen({width: '300px'})
  
  
  # form change detection
  $(".guarded_form :input").change ->
    $(this).closest('form').data 'changed', true
    window.onbeforeunload = -> "Achtung: Die Änderungen wurden noch nicht gespeichert!"
  
  $('.guarded_form_save').click ->
    window.onbeforeunload = null
  
  
  # sorting ajax list
  $('a.sort-link').click ->
    $('#sort').val($(this).attr('href'))
    $('#direction').val($(this).attr 'data-sort-direction')
    $('form').submit()
    false
    
  
  # add and remove url lines for settings
  $('a.add-url-link').click ->
    $('#url-tags').append('<span> ... <input id="mail_restrictions__prefix" name="mail_restrictions[][prefix]" type="text" value="" /> ... @ '+
                          '<input id="mail_restrictions__suffix" name="mail_restrictions[][suffix]" type="text" value="" /><br/></span>')
                
  $('a.remove-url-link').click ->
    $('#url-tags span:last-child').remove()
    
  # open links in new window
  $('.new-window').click ->
    window.open this.href
    return false