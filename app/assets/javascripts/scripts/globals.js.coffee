$ =>
  # activate chosen
  $(".chzn-select").chosen()
  
  # form change detection
  $(".guarded_form :input").change ->
    $(this).closest('form').data 'changed', true
    window.onbeforeunload = -> "Achtung: Die Änderungen wurden noch nicht gespeichert!"
  
  $('.guarded_form_save').click ->
    window.onbeforeunload = null
  
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