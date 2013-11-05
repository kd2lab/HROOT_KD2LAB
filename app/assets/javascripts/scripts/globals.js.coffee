$ ->
  # todo remove this later - adds translation errors to the top of the page
  $ ->
    console.log "test"
    s = $('html')[0].innerHTML
    arr = s.match(/"translation missing: (.*?)"/gi)
    if arr
      arr = arr.map (s) -> s.slice(22, -1)
      arr.forEach (s) ->
        console.log s
        $('body').prepend(s+"<br/>")
  
  
  # activate dropdown toggle - todo remove if not needed
  # $('.dropdown-toggle').dropdown()
  
  # activate bootstrap tooltips
  $(".tool-tip").tooltip({trigger: 'hover'})
  
  # calendar tooltips - maybe optimize this
  $('.event-qtip').each ->
    $(this).popover
      html: true,
      title: $(this).attr('data-title'),
      content: "<i> #{ $(this).attr('data-location') }</i>                
                <br/><br/>
                #{ $(this).attr('data-exp') }
                <br/><br/>
                #{ $(this).attr('data-count') }
                <br/><br/>
                #{ ($(this).attr('data-before') ? $(this).attr('data-before')+'<br/>' : '') }
                #{ ($(this).attr('data-after') ? $(this).attr('data-after')+'<br/>' : '') }",
      trigger: 'hover',
      container: 'body'
  
  # activate timepicker
  $('.timepicker').timepicker()
  
  # activate datepicker js
  $('.datepicker').datepicker(
    language: $('body').data('locale') 
  )
        
  # activate chosen
  # todo clean this up
  
  $(".chzn-select-search").chosen({disable_search_threshold: 10, width: '400px'})
  $(".chzn-select-search-tags").chosen({width: '150px'})

  $(".chzn-select").chosen({width: '150px'})
  $(".chzn-select-register").chosen({width: '300px'})
  
  
  # form change detection
  $(".guarded_form :input").change ->
    $(this).closest('form').data 'changed', true
    window.onbeforeunload = -> "Achtung: Die Änderungen wurden noch nicht gespeichert!"
  
  $('.guarded_form_save').click ->
    window.onbeforeunload = null
  
  
  # sorting ajax list
  $('a.sort-link').click ->
    $('#sort').val($(this).attr('href'))
    $('#direction').val($(this).attr 'data-sort-direction')
    $('form').submit()
    false
    
  
  # add and remove url lines for settings
  $('a.add-url-link').click ->
    $('#url-tags').append('<span> ... <input id="mail_restrictions__prefix" name="mail_restrictions[][prefix]" type="text" value="" /> ... @ '+
                          '<input id="mail_restrictions__suffix" name="mail_restrictions[][suffix]" type="text" value="" /><br/></span>')
                
  $('a.remove-url-link').click ->
    $('#url-tags span:last-child').remove()
    
  # open links in new window
  $('.new-window').click ->
    window.open this.href
    return false