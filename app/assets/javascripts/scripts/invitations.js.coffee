update_calculations = () ->
  anzahl = $("#count").text()
  size = $('#experiment_invitation_size').val()
  hours = $('#experiment_invitation_hours').val() 

  blocks = 0
  minutes = 0
  paket = size  
  
  #versand simulieren
  while anzahl > 0
    if paket > 50
      anzahl  -= 50
      paket -= 50
    else
      anzahl-= paket
      paket = 0  
      
    minutes += 5
    
    if minutes >= hours*60
      paket += size
      minutes = 0
      blocks += 1
      
  stunden = parseInt(blocks*hours + minutes/60)
  minuten = minutes % 60    
      
  $("#info_text").text("Das Versenden aller E-Mails bei diesen Einstellungen dauert ca. "+ 
    stunden+ " Stunden und "+minuten+" Minuten.")     
  
  
$ ->
  $('#experiment_invitation_size').change ->
    update_calculations()
    
  $('#experiment_invitation_hours').change ->
    update_calculations()
  
  update_calculations()
  
$ ->
  $('#invitationmenu').mouseleave ->
    $('.items').slideUp('fast')
  
  $('.invitation_menu').click -> $('.items').slideToggle('fast'); false
  
  $('.save_invitation').live 'click', ->
    if $(this).attr('data-name') && !confirm "Achtung: Die bisher gespeicherten Daten werden dadurch überschrieben! Wollen Sie fortfahren?"
        return false
      
    name = $(this).attr('data-name') || prompt "Bitte geben Sie einen Namen für die Vorlage an:", "Vorlagenname"
    
    if name != null && name.length > 0
      $(".items").load "", 
        { mode: 'create', templatename: name, value: $('#invitation_text').val()}
    
    $('.items').slideToggle('fast')
    false
    
  $('.load_invitation').live 'click', ->
    if confirm("Soll die Vorlage geladen und der aktuelle Text ersetzt werden?")
      $.post "", { mode: 'load', templatename: $(this).attr('data-name') }, (data) ->
        $('#invitation_text').val(data)
      
    $('.items').slideToggle('fast')
    false
    
  $('.delete_invitation').live 'click', ->
    if confirm "Soll die Vorlage wirklich gelöscht werden?"
      $(".items").load "", 
        { mode: 'delete', templatename: $(this).attr('data-name') }
  
    $('.items').slideToggle('fast')
    false
      