$ ->
  $('#add-privilege').chosen().change ->
    selected_id = $(this).val()
    selected_text = $('#add-privilege option:selected').text()
    
    if $('#privilege-table tr[data-id='+selected_id+']').length == 0
      select = $('<select/>')
        .addClass('chzn-select-roles')
        .attr('data-placeholder', $('#privilege-table').data('rights-label'))
        .attr('multiple', 'multiple')
        .attr('name', 'privileges[][list][]')
        .css('width', '500px')

      rights = $('#privilege-table').data('rights')
      default_rights = $('#privilege-table').data('default-rights')
      
      $('<option />', {value: a[1], text: a[0], selected: ($.inArray(a[1], default_rights) > -1 ? "selected": "")}).appendTo(select) for a in rights
    

      hidden1 = $('<input>').attr({
        type: 'hidden',
        name: 'privileges[][id]',
        value: selected_id
      })

      hidden2 = $('<input>').attr({
        type: 'hidden',
        name: 'privileges[][name]',
        value: selected_text
      })

      button = $('<button/>').addClass('close removeline').text('×')

      row = $('<tr/>').attr('data-id', selected_id).append(
        $('<td/>').append(hidden1, hidden2, selected_text)
      ).append(
        $('<td/>').append(select, button)
      ).insertBefore("#privilege-table tr:last")

      select.chosen()
    
  $("#privilege-table").on "click", ".removeline", ->
    $(this).closest('tr').remove()
    false  