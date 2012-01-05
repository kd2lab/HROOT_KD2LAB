update_languages = ->
  if $('#user_lang1').val() != "" && $('#user_lang2').val() != ""
    $('#lang3').show()
  else
    $('#user_lang3').val('')
    $('#lang3').hide()
    
  if $('#user_lang1').val() != ""
    $('#lang2').show()
  else
    $('#user_lang2').val('')
    $('#lang2').hide()    
  
$ ->
  update_languages()
  
  $('#user_lang1, #user_lang2').change(update_languages)
      