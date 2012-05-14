$ ->
  tagalize = (id) ->
    return if id.length == 0
    
    # remember selected item in drowdown
    selected = -1
    
    # remember ajax calls
    xhr = null  
    
    # id merken
    $this = id
    
    # name der form variablen
    $varname = id.attr('name')

    # tags
    $tags = id.attr('value')

    # hack for blur
    blur = true

    # main div
    div = $("<div class='its_tag_panel'><input id='its_new_tag' type='text'></div>")
    $this.replaceWith(div)
  
    # prepare dropdown
    dropdown = $("<div id='its_drop_down'>the list</div>").appendTo(div).hide()
  
    $(dropdown).hover(
      () -> blur = false 
      () -> 
        blur = true
        selected = -1
        update_selection()
    )
    
    update_selection = () ->
      $('#its_drop_down li').removeClass('selected')
      if selected >= 0
        $('#its_drop_down li').eq(selected).addClass('selected')
    
    insert_tag = (text) ->
      if text.length > 0
        $("<div class='its-tag'>"+text+" <a class='remove_tag'>x</a><input name='"+$varname+"[]' type='hidden' value='"+text+"'></div>").insertBefore('#its_new_tag')
        $('#its_new_tag').val("")
        dropdown.hide() 
        selected = -1   
    
    $.each $tags.split(','), (i, elem) ->
      insert_tag($.trim(elem))
    
    update_dropdown = (result) ->
      if result && result.length > 0 && $('#its_new_tag').val().length > 1 
        ul = $("<ul></ul>")
        $.each result, (i, elem) -> ul.append ("<li>"+elem+"</li>")
        dropdown.html(ul).show()
        selected = -1  
      else
        dropdown.hide()
        selected = -1
    
    $('#its_new_tag').blur (e) ->
      insert_tag($(this).val()) if blur
  
    $(div).on "click", (e) ->
      $('#its_new_tag').focus()
  
    $(div).on "click", ".remove_tag", (e) ->
      $(this).parent().remove()
      e.stopPropagation()
      
    $(div).on "click", "li", (e) ->
      insert_tag($(this).text())
      blur = true
      update_dropdown()
      $('#its_new_tag').focus()
      
    $(div).on "mouseenter", "li", (e) ->
      selected = parseInt($(this).index())
      update_selection()
      
    $('#its_new_tag').keydown (e) ->
      switch e.which
        when 38, 40, 13, 9, 188
          e.preventDefault()
      if $(this).val().length == 0 
        if e.which == 8 
          $(this).prev().remove()     
          
    $('#its_new_tag').keyup (e) ->
      switch e.which
        when 9, 13, 188
          e.preventDefault()
          if $(this).val().length > 0           
            if selected == -1
              insert_tag $(this).val()
            else
              insert_tag $('#its_drop_down li').eq(selected).text() 
        when 38
          selected = selected - 1 if (selected >= 0) 
          update_selection()
        when 40
          selected = selected + 1 if selected < $('#its_drop_down li').length-1
          update_selection()  
        else
          if $(this).val().length <= 1
            update_dropdown()
          else
            $this = $(this)
            captured = $this.val()
            
            ajaxcall = () ->
              if captured == $this.val()
                if xhr
                  xhr.abort()
        
                xhr = $.ajax 
                  url: 'autocomplete_tags'
                  type: 'GET'
                  dataType: 'json'
                  data: { query: $this.val() }
                  success: (result) ->
                    update_dropdown(result)
            setTimeout ajaxcall, 200       
        
  tagalize($('#experiment_tag_list'))