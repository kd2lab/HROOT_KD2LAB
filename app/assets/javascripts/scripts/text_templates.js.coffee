$ ->
  $('.text-templates').mouseleave ->
    $('.items').slideUp('fast')

  $('.templates-link').live 'click', -> 
    $('.items', $(this).parent().parent()).slideToggle('fast'); false

  $('.save_template').live 'click', ->
    if $(this).attr('data-name') && !confirm "Achtung: Die bisher gespeicherten Daten werden dadurch überschrieben! Wollen Sie fortfahren?"
      return false
    
    name = $(this).attr('data-name') || prompt "Bitte geben Sie einen Namen für die Vorlage an:", "Vorlagenname"
    element_id = $(this).attr('data-element-id')
    
    if name != null && name.length > 0
      $('.items[data-element-id="'+element_id+'"]').load "/admin/templates", 
        { mode: 'create', templatename: name, value: $('#'+element_id).val(), element_id: element_id}
  
    $('.items[data-element-id="'+element_id+'"]').slideToggle('fast')
    false
  
  $('.load_template').live 'click', ->
    element_id = $(this).attr('data-element-id')
    if confirm("Soll die Vorlage geladen und der aktuelle Text ersetzt werden?")
      $.post "/admin/templates", { mode: 'load', templatename: $(this).attr('data-name'), element_id: element_id }, (data) =>
        $('#'+element_id).val(data)
    
    $('.items[data-element-id="'+element_id+'"]').slideToggle('fast')
    false
  
  $('.delete_template').live 'click', ->
    element_id = $(this).attr('data-element-id')
    if confirm "Soll die Vorlage wirklich gelöscht werden?"
      $('.items[data-element-id="'+element_id+'"]').load "/admin/templates", 
        { mode: 'delete', templatename: $(this).attr('data-name'), element_id: element_id  }

    $('.items[data-element-id="'+element_id+'"]').slideToggle('fast')
    false