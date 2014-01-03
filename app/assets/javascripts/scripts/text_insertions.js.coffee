$ ->
  $('body').on 'click', '.insert_text', (e)->
    element_id = $(this).closest('.text-insertions').attr('data-element-id')  
    $('#'+element_id).insertAtCaret($(this).attr('data-name'))
    $('[data-toggle="dropdown"]').parent().removeClass('open');
    false