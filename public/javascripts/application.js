
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
  
  // activate chosen
  $(".chzn-select").chosen()
  
  // form change detection
  $(".guarded_form :input").change(function() {
    $(this).closest('form').data('changed', true);
    window.onbeforeunload = function () { return "Achtung: Die Änderungen wurden noch nicht gespeichert!" };
  });
  
  $('.guarded_form_save').click(function() {
    window.onbeforeunload = null
  });
  
  
})