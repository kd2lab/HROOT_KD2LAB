
// ajax experiment list
$(function () {  
  $('#experiments th a, #experiments .pagination a, #users th a, #users .pagination a').live('click', function () {  
    $.getScript(this.href);  
    return false;  
  });  
  
  // Search form.  
  $('#experiment_search, #user_search').submit(function () {  
    $.get(this.action, $(this).serialize(), null, 'script');  
    return false;  
  });
})