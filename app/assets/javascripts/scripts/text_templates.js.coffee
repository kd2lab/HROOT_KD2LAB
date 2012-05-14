$ ->
  
  $('.save_template').live 'click', ->
    if $(this).attr('data-name') && !confirm "Achtung: Die bisher gespeicherten Daten werden dadurch überschrieben! Wollen Sie fortfahren?"
      return false
    
    name = $(this).attr('data-name') || prompt "Bitte geben Sie einen Namen für die Vorlage an:", "Vorlagenname"
    element_id = $(this).closest('.text-templates').attr('data-element-id')
    
    if name != null && name.length > 0
      $.post "/admin/templates", { mode: 'create', templatename: name,  value: $('#'+element_id).val(), element_id: element_id }, (data) =>
        $('.template-menu').replaceWith(data)
    false
  
  $('.load_template').live 'click', ->
    element_id = $(this).closest('.text-templates').attr('data-element-id')
    if confirm("Soll die Vorlage geladen und der aktuelle Text ersetzt werden?")
      $.post "/admin/templates", { mode: 'load', templatename: $(this).attr('data-name')}, (data) =>
        $('#'+element_id).val(data)
    false
  
  $('.delete_template').live 'click', ->
    if confirm "Soll die Vorlage wirklich gelöscht werden?"
      $.post "/admin/templates",{ mode: 'delete', templatename: $(this).attr('data-name')}, (data) =>
        $('.template-menu').replaceWith(data)  
    false