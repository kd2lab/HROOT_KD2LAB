$ ->
  $('.files').fileTree()
  

  #$('*[data-poload]').popover({title: "test", html:true, content: "test", trigger: 'click', placement: 'left'})
  
  $('*[data-poload]').on 'click', (evt)->
     e = $(this)
     e.off('click')  
     $.get e.data('poload'), (d)->
       e.popover({title: d.subject, html:true, content: d.message, trigger: 'manual', placement: 'left'})
       
       e.click (evt)->
         was_open = $(this).hasClass('opened-popup')
         $('.opened-popup').popover('hide').removeClass('opened-popup')  
         
         if !was_open
           $('.opened-popup').popover('hide').removeClass('opened-popup') 
           $(this).addClass('opened-popup')
           $(this).popover('toggle')
         
         evt.preventDefault()
         false
         
       e.trigger('click')

     evt.preventDefault()

  $('body').click ->
    $('.opened-popup').popover('hide').removeClass('opened-popup')  
    
    
  # todo later remove automatic capturing of translation errors
  $ ->
    s = $('html')[0].innerHTML
    arr = s.match(/translation missing: ([\w\.]*)/gi)
    if arr
      arr = arr.map (s) -> s.slice(21)
      $.post('/home/translations', {missing: arr})
    
  # activate bootstrap tooltips
  $(".tool-tip").tooltip({trigger: 'hover', container: 'body'})
  
  # calendar tooltips
  $('.event-popover').each ->
    $(this).popover
      html: true,
      title: $(this).data('title')+' '+$(this).data('timestr'),
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
  # todo later clean this up
  
  $(".chzn-select-search").chosen({disable_search_threshold: 10, width: '400px'})
  $(".chzn-select-search-tags").chosen({width: '150px'})

  $(".chzn-select").chosen({width: '150px'})
  $(".chzn-select-roles").chosen({width: '500px'})
  
  $(".chzn-select-register").chosen({width: '300px'})
  $(".chzn-select-experiments").chosen({width: '500px'})
  
  
  # form change detection
  $(".guarded_form :input").change ->
    $(this).closest('form').data 'changed', true
    window.onbeforeunload = -> $('.guarded_form').data('alert')
  
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