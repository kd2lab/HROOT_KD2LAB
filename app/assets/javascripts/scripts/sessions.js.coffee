$ ->
  # buttons with forms
  $('.session_new').live 'submit',  ->
    $.get(this.action, null, null, "script")
    false
  
  $('.session_update').live 'submit', ->
    $.post(this.action, $(this).serialize(), null, "script")
    false
  


  
  # links
  $('.session_new_subsession, .session_edit').live 'click',  ->
    $.get(this.href, null, null, "script")
    false
     
  $('.session_duplicate').live 'click', ->
    $.post(this.href, null, null, "script")
    false
  
  $('.session_delete').live 'click', ->
    $.post(this.href, {_method: 'delete'}, null, "script")
    false

  $('.session_close').live "click", ->
    $.get(this.action, null, null, "script")
    false
      