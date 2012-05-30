$ ->
  # close button on filters and reopen
  updateFilters = () ->
    $('.filter-block[data-enabled=false]').each () ->
      $(this).fadeOut()
      $(this).find(':input').attr("disabled", "disabled")
    $('.filter-block[data-enabled=true]').each () ->
      $(this).show()
      $(this).find(':input').removeAttr("disabled")
      
  $('<a href="#" class="close"><i class="icon-remove-circle"/></a>').prependTo('.filter-block').click ->
    $(this).parent().attr('data-enabled', 'false')
    updateFilters()
    false
    
  $('a.open-link').click ->
    $($(this).attr('href')).attr('data-enabled', 'true')
    updateFilters()
    false
    
  updateFilters()
  
  
  
  # add and remove buttons for tag filters
  $('a.add-link').click ->
    i = parseInt $('#filter_exp_tag_count').val()
    if i < 10
       $('#exp_filter_'+i).fadeIn()
       $('#filter_exp_tag_count').val i+1
    false

  $('a.remove-link').click ->
    i = parseInt $('#filter_exp_tag_count').val()-1
    if i > 0
       $('#exp_filter_'+i).fadeOut()
       $('#filter_exp_tag_count').val i
    false
    
  # integrate pagination and filters  
  $('#user_search .pagination a').click ->
    $('#page').val($(this).attr('data-page'))
    $('#user_search').submit();
    return false