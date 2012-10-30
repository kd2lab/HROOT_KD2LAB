// contains qtip code for popups


$(function () {  
  
  // test
  
  $('.event-qtip').each(function() {
    $(this).qtip({
       content: "<h3>"+$(this).attr('data-title')+"</h3>"
                
                +"<i>"+$(this).attr('data-location')+"</i><br/><br/>"
                +$(this).attr('data-exp')+"<br/><br/>"
                +$(this).attr('data-count')+"<br/><br/>"
                +($(this).attr('data-before') ? $(this).attr('data-before')+"<br/>" : "")
                +($(this).attr('data-after') ? $(this).attr('data-after')+"<br/>" : "")
                
       ,
       show: { when: 'mouseover', solo : 'true'},
       hide: { when: 'mouseout' },
       position: {
         corner: {
           target: 'rightMiddle',
           tooltip: 'leftMiddle'
         }  
       },
       style: { 
             tip: 'leftMiddle' // Notice the corner value is identical to the previously mentioned positioning corners
          }
    })
  });
  
  
  // qtip generic
  $('.popup').each(function() {
    $(this).qtip({
      content: $(this).attr('data-popup'),
      show: 'mouseover',
      hide: 'mouseout',
      position: {
        corner: {
          target: 'topMiddle',
          tooltip: 'bottomMiddle'
        }  
      },
      style: { 
        tip: 'bottomMiddle' // Notice the corner value is identical to the previously mentioned positioning corners
      }
    })
  });
    
  // qtip for study
  // Use the each() method to gain access to each elements attributes
  $('.study_name_popup').each(function() {
    $(this).qtip({
      content: $(this).attr('data-text'),
      position: {
         corner: {
           target: 'topMiddle',
           tooltip: 'bottomleft'
         }  
       },
       show: 'mouseover',
       hide: 'mouseout',
       style: {
         tip: 'bottomLeft'
       }
    })
  });
  
})