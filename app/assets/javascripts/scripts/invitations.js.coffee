

calc_times = (anzahl, size, hours) ->
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
  
  if minutes > 0 
    minutes -= 5    
  stunden = parseInt(blocks*hours + minutes/60)
  minuten = minutes % 60    
  return {stunden: stunden, minuten:minuten}

update_calculations = () ->
  anzahl1 = $("#count").text()
  anzahl2 = $("#count_total").text()
  size = $('#experiment_invitation_size').val()
  hours = $('#experiment_invitation_hours').val() 

  s = calc_times(anzahl1, size, hours)
  s.minuten = "0"+s.minuten if s.minuten < 10  

  s2 = calc_times(anzahl2, size, hours)
  s2.minuten = "0"+s2.minuten if s2.minuten < 10  
    
  $("#info_text").text(s.stunden+ ":"+s.minuten)     
  $("#info_text2").text(s2.stunden+ ":"+s2.minuten)     
    
$ ->
  $('#experiment_invitation_size').change ->
    update_calculations()
    
  $('#experiment_invitation_hours').change ->
    update_calculations()
  
  update_calculations()
  
  
  
