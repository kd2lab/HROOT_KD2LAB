$ ->
  # todo refactor this, check
  
  build_select = (id) ->
    rights = $('#usertable').data('rights')
    right_string = ('<option value="'+a[1]+'">'+a[0]+'</option>' for a in rights)
    right_select = '<select class="chzn-select-roles" data-placeholder="'+$('#usertable').data('rights-label')+'" id="rights'+id+'" multiple="multiple" name="rights['+id+'][]" style="width:600px">'+right_string.join('')+'</select>'
    
  
  $('#add_user').chosen().change ->
    selected_id = $(this).val()
    selected_text = $('#add_user option:selected').text()
    
    # is this row doesn't exist yet...
    if $('#usertable tr[data-id='+selected_id+']').length == 0
      hidden_field = "<input type='hidden' name='user_submitted[]' value='"+selected_id+"'>"
      row =  "<tr data-id='"+selected_id+"'><td>"+hidden_field+selected_text+"</td><td>"+build_select(selected_id)+"<button class='close removeline'' href='#'>×</button></td></tr>"
      $('#usertable tr:last').before row
      
      # activate chosen
      $('#rights'+selected_id).chosen()
   
   
    # reset field
    $(this).val('')
    $(this).trigger("liszt:updated")
    
  $("#usertable").on "click", ".removeline", ->
    $(this).closest('tr').remove()
    false