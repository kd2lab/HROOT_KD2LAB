$ ->
  # close button on filters and reopen
  updateFilters = () ->
    $('.filter-block[data-enabled=false]').each () ->
      $(this).find(':input').attr("disabled", "disabled")
    $('.filter-block[data-enabled=true]').each () ->
      $(this).show()
      $(this).find(':input').removeAttr("disabled")
      
  $('<a href="#" class="close"><i class="icon-remove-circle"/></a>').prependTo('.filter-block').click ->
    $(this).parent().attr('data-enabled', 'false')
    updateFilters()
    false
    
  $('a.open').click ->
    $('#'+$(this).data('filter')).attr('data-enabled', 'true')
    updateFilters()
    false
    
  updateFilters()
  
    
  # integrate pagination and filters  
  $('#user_search .pagination a' ).click ->
    page = $(this).attr('data-page')
    
    if (page != undefined)
      $('#page').val(page)
      $('#user_search').submit();
    
    return false