/*
 * Smart event highlighting
 * Handles when events span rows, or don't have a background color
 */
jQuery(document).ready(function($) {
  var highlight_color = "#2EAC6A";
  
  // todo solve with delegate
  // highlight events that have a background color
  $('body').on('mouseover', '.ec-event-bg', function() {
    event_id = $(this).attr("data-event-id");
        event_class_name = $(this).attr("data-event-class");
    $(".ec-"+event_class_name+"-"+event_id).css("background-color", highlight_color);
  });

  $('body').on('mouseout', '.ec-event-bg', function() {
    event_id = $(this).attr("data-event-id");
        event_class_name = $(this).attr("data-event-class");
    event_color = $(this).attr("data-color");
    $(".ec-"+event_class_name+"-"+event_id).css("background-color", event_color);
  });
  
  // highlight events that don't have a background color
  $('body').on('mouseover', '.ec-event-no-bg', function() {
    ele = $(this);
    ele.css("color", "white");
    ele.find("a").css("color", "white");
    ele.find(".ec-bullet").css("background-color", "white");
    ele.css("background-color", highlight_color);
  });

  $('body').on('mouseout', '.ec-event-no-bg', function() {
    ele = $(this);
    event_color = $(this).attr("data-color");
    ele.css("color", event_color);
    ele.find("a").css("color", event_color);
    ele.find(".ec-bullet").css("background-color", event_color);
    ele.css("background-color", "transparent");
  });
});