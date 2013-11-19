$ ->
  
  $('#files').fileTree();
  
  # todo remove this later - adds translation errors to the top of the page
  $ ->
    s = $('html')[0].innerHTML
    arr = s.match(/translation missing: ([\w\.]*)/gi)
    if arr
      arr = arr.map (s) -> s.slice(21)
      $.post('/home/translations', {missing: arr})
  
  
  # todo what is this
  # activate dropdown toggle - todo remove if not needed
  # $('.dropdown-toggle').dropdown()
  
  # activate bootstrap tooltips
  $(".tool-tip").tooltip({trigger: 'hover', container: 'body'})
  
  # calendar tooltips
  $('.event-popover').each ->
    $(this).popover
      html: true,
      title: $(this).data('title'),
      content: "<i> #{ $(this).data('location') }</i>                
                <br/><br/>
                #{ $(this).data('exp') }
                <br/><br/>
                #{ $(this).data('count') }
                <br/><br/>
                #{ if $(this).data('before') != undefined then $(this).data('before')+'<br/>' else ''  }
                #{ if $(this).data('after') != undefined then $(this).data('after')+'<br/>' else '' }",
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
  
    
  # open links in new window
  $('.new-window').click ->
    window.open this.href
    return false