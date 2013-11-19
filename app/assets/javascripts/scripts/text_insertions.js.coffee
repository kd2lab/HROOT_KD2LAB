$ ->
  $('body').on 'click', '.insert_text', ->
    element_id = $(this).closest('.text-insertions').attr('data-element-id')  
    $('#'+element_id).insertAtCaret($(this).attr('data-name'))
    false