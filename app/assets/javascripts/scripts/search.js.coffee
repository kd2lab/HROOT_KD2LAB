$ ->
  #todo cleanup
  
  # disable all invisible controls to stop form submission
  $('.search-block:hidden').find(':input').attr('disabled', 'disabled')
      
  $('.close-search-field').click ->
    $(this).parent().fadeOut()
    $(this).parent().find(':input').attr('disabled', 'disabled')
    false
  
  $('.open-search-box').click ->
    field_name = $(this).data("field")
    $('#'+field_name).find(':input').removeAttr('disabled')
    $('#'+field_name).show()
    false


  # add and remove buttons for tag search
  $('a.add-link').click ->
    $lastline = $(this).parent().find('.tag-row').last()
    $clone = $lastline.clone()
    $lastline.after($clone)
    
    $(this).parent().find('.chzn-select-search-tags').last().removeClass("chzn-done").removeAttr("id").css("display", "block").next().remove();
    $(this).parent().find('.chzn-select-search-tags').last().chosen();
    
    false

  $('a.remove-link').click ->
    if $(this).parent().find('.tag-row').length > 1
      $(this).parent().find('.tag-row').last().remove()
    false