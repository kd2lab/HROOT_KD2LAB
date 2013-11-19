$ ->
  
  $('body').on 'click', '.save_template', ->
    $t = $(this).closest('.text-templates')
    
    # bail out if no confirmation for overwrite
    if $(this).data('name') && !confirm($t.data('confirm-save'))    
      false

    name = $(this).data('name') || prompt $t.data('prompt-text'), $t.data('prompt-title')
    element_id = $t.data('element-id')

    # if a name was chosen, submit the current content of the element and the name
    if name != null && name.length > 0
      $.post $t.data('url'), { mode: 'create', templatename: name,  value: $('#'+element_id).val(), element_id: element_id }, (data) ->
        $t.replaceWith(data)
    
    false
  
  $('body').on 'click', '.load_template', ->
    $t = $(this).closest('.text-templates')
    element_id = $t.data('element-id')
    
    if confirm($t.data('confirm-replace'))
      $.post $t.data('url'), { mode: 'load', templatename: $(this).data('name')}, (data) =>
        $('#'+element_id).val(data)
    false
  
  $('body').on 'click', '.delete_template', ->
    $t = $(this).closest('.text-templates')
    
    if confirm $t.data('confirm-delete')
      $.post $t.data('url') ,{ mode: 'delete', templatename: $(this).data('name')}, (data) =>
        $t.replaceWith(data)
    
    false