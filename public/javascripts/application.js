

$(function () {  
  // ajax experiment list
  $('#experiments th a, #experiments .pagination a').live('click', function () {  
    $.getScript(this.href);  
    return false;  
  });  
  
  // Search form.  
  $('#experiment_search').submit(function () {  
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
  
  // close button on filters and reopen
  $('a.close-link').click(function() {
    $($(this).attr('href')).fadeOut();
    $("input[id=active_"+$(this).attr('href').substring(1)+"]").val("");
    return false;
  });
  
  $('a.open-link').click(function() {
    $($(this).attr('href')).fadeIn();
    $("input[id=active_"+$(this).attr('href').substring(1)+"]").val("1");
    
    return false;
  });
  
  // add and remove buttons for experiment type
  $('a.add-link').click(function() {
    var i = parseInt($('#exp_typ_count').val());
    if (i < 10) {
       $('#exp_filter_'+i).fadeIn();
       $('#exp_typ_count').val(i+1);
    }
    
    return false;
  });
  
  $('a.remove-link').click(function() {
    var i = parseInt($('#exp_typ_count').val())-1;
    if (i > 0) {
       $('#exp_filter_'+i).fadeOut();
       $('#exp_typ_count').val(i);
    }
    
    return false;
  });
  
  // sorting of participants list
  $('a.sort-link').click(function() {
    $('#sort').val($(this).attr('href'));
    $('#direction').val($(this).attr('data-sort-direction'));
    $('form').submit();
    return false;
  });
  
  // select and deselect all checkboxes
  $('a.all-link').click(function() {
    $('form input[type=checkbox]').attr('checked', true);
    return false;
  });
  
  $('a.none-link').click(function() {
    $('form input[type=checkbox]').attr('checked', false);
    return false;
  });
  
  
  // on submit of "all" check all boxes
  $('.submit_all').click(function() {
    $('form input[type=checkbox]').attr('checked', true);
  });
  
  
})