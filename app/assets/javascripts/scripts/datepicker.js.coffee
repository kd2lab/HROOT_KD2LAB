
$ ->  
  $.datepicker.regional['de'] = {
		closeText: 'schließen',
		prevText: '&#x3c;zurück',
		nextText: 'Vor&#x3e;',
		currentText: 'heute',
		monthNames: ['Januar','Februar','März','April','Mai','Juni',
		'Juli','August','September','Oktober','November','Dezember'],
		monthNamesShort: ['Jan','Feb','Mär','Apr','Mai','Jun',
		'Jul','Aug','Sep','Okt','Nov','Dez'],
		dayNames: ['Sonntag','Montag','Dienstag','Mittwoch','Donnerstag','Freitag','Samstag'],
		dayNamesShort: ['So','Mo','Di','Mi','Do','Fr','Sa'],
		dayNamesMin: ['So','Mo','Di','Mi','Do','Fr','Sa'],
		weekHeader: 'Wo',
		dateFormat: 'dd.mm.yy',
		firstDay: 1,
		isRTL: false,
		showMonthAfterYear: false,
		yearSuffix: ''}
  
  $.datepicker.setDefaults $.datepicker.regional['de']
  
  $.timepicker.regional['de'] = {
  	timeOnlyTitle: 'timeonlytitle',
  	timeText: 'Zeit',
  	hourText: 'Stunden',
  	minuteText: 'Minuten',
  	secondText: 'Sekunden',
  	millisecText: 'Millisekunden',
  	currentText: 'Jetzt',
  	closeText: 'Schliessen',
  	ampm: false
  };
  $.timepicker.setDefaults($.timepicker.regional['de']);
  
  #$('#session_start_date').datepicker $.datepicker.regional[ 'de' ]
  $('#session_start_date').datetimepicker {
    	hour: 12,
    	minute: 0
  };
