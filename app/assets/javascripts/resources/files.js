
if(jQuery) (function($){
  
  function post_to_url(action, method, input) {
      "use strict";
      var form;
      form = $('<form />', {
          action: action,
          method: method,
          style: 'display: none;'
      });
      if (typeof input !== 'undefined') {
        $('<input />', {type: 'hidden', name: 'authenticity_token', value: $('meta[name="csrf-token"]').attr('content')}).appendTo(form)
          $.each(input, function (name, value) {
              $('<input />', {
                  type: 'hidden',
                  name: name,
                  value: value
              }).appendTo(form);
          });
      }
      form.appendTo('body').submit();
  }
  
	$.extend($.fn, {
		fileTree: function(o) {
			if( !o ) var o = {};
			if( o.action == undefined ) o.action = 'filelist';
			if( o.folderEvent == undefined ) o.folderEvent = 'click';
			if( o.loadMessage == undefined ) o.loadMessage = 'Loading...';
			
      var $contextMenu = $("#context-menu");

			$(this).each( function() {
        var $filelist = $(this)        
        var $clicked_li;
        
        function handleFileUpload(files, $droptarget) {
           for (var i = 0; i < files.length; i++) {        
                var size = parseInt(files[i].size/1024);        
                var sizeStr = (size > 1024) ? (size/1024).toFixed(2)+" MB" : size.toFixed(2)+" KB"        
                
                var $elem = $('<div class="statusbar">')
                             .append($('<div class="filename">').html(files[i].name))
                             .append($('<div class="filesize">').html(sizeStr))
                             .append('<div class="progress progress-striped active"><div class="bar" style="width: 1%;"></div></div>')
                             .append('<div class="abort-button"><a class="btn btn-danger btn-mini">Stop</a></div></div>')
                             .insertAfter($filelist)
              
                formData = new FormData();
                formData.append('file', files[i]);
                formData.append('dir', $droptarget.data('path'))
              
                var jqXHR=$.ajax({
                    $elem: $elem, 
                    file: files[i],
                    xhr: function() {
                        var $bar = this.$elem.find('.bar');
                        var xhrobj = $.ajaxSettings.xhr();
                        if (xhrobj.upload) {
                            xhrobj.upload.addEventListener('progress', function(event) {
                                var percent = 0;
                                var position = event.loaded || event.position;
                                var total = event.total;
                                if (event.lengthComputable) {
                                    percent = Math.ceil(position / total * 100);
                                }
                                
                                //Set progress
                                $bar.css({width: percent+'%'});
                            });
                        }
                        return xhrobj;
                    },
                    url: 'upload',
                    type: 'post',
                    contentType:false,
                    processData: false,
                    cache: false,
                    data: formData,
                    success: function(data) {
                        this.$elem.children('.progress').removeClass('active');
                        this.$elem.delay(5000).fadeOut(1000, function() { $(this).remove() })
                        
                        // reload full tree
                        updateTree( $droptarget);

                        if (data.result == "no_overwrite") {
                          alert(this.file.name+" konnte nicht hochgeladen werden, da bereits eine gleichnamigee Datei existiert.");
                        }
                        
                    }
                });
                
                $elem.find('.abort-button a').click(function() {
                  jqXHR.abort();
                  $(this).closest('.statusbar').remove()
                })
           }
        }
        
        // handle click on file - show context menu
        $filelist.on("click", "li", function (e) {
          if (e.which == 3) return;

          $contextMenu.hide();
          
          if (e.shiftKey) {
            $(this).addClass('selected');
          
            f = $filelist.find('li.selected').first()[0]
            l = $filelist.find('li.selected').last()[0]
            
            var sel = false;
            $filelist.find('li').each(function() {
              if (this == f) sel = true;
              if (this == l) sel = false;
              if (sel) { $(this).addClass('selected')}
            })
          } else if (e.metaKey) {
            $(this).toggleClass('selected');  
          } else {
            $filelist.find('li').removeClass('selected');
            $(this).addClass('selected');
          }
          return false;
        });

        // handle doubleclick on closed folder - load subfolder
        $filelist.on("dblclick", "li.directory.collapsed", function (e) {
            $(this).removeClass('collapsed').addClass('expanded')
            showTree($(this), true, [])
            e.preventDefault();
            return false;
        });

        // handle click on open folder - load subfolder
        $filelist.on("dblclick", "li.directory.expanded", function (e) {
            $(this).removeClass('expanded').addClass('collapsed')  
            $(this).find('UL').slideUp({ duration: 200 });
            e.preventDefault();
            return false;
        });
        
        // show context menu
        $filelist.on('contextmenu', 'li', function(e){ 
          $clicked_li = $(this)
          
          if (!$clicked_li.hasClass('selected')) {
            $filelist.find('li').removeClass('selected');
            $clicked_li.addClass('selected')
          }

          $contextMenu.css({
            position: "absolute",
            display: "block",
            left: e.pageX,
            top: e.pageY
          });
          
          e.preventDefault();
          return false; 
        });

        $filelist.on('click', function(e){ 
          $clicked_li = null
          $filelist.find('li').removeClass('selected');
          $contextMenu.hide();
          return false
        });

        $filelist.on('contextmenu', function(e){ 
          $clicked_li = null
          $filelist.find('li').removeClass('selected');
          $contextMenu.css({
            position: "absolute",
            display: "block",
            left: e.pageX,
            top: e.pageY
          });
          return false
        });
        
        // create new folder
        $contextMenu.on("click", "a.new-folder", function () {
          var parent = '';
          if ($clicked_li != null) parent = $clicked_li.data('path')  

          $contextMenu.hide();
          
          dirname = prompt($filelist.data('folder-question'))
          if (dirname != null && dirname.length > 0) {
            $.post('new_folder', {dirname: dirname, parent: parent}, function(e) {
              if ($($clicked_li).closest('li.directory').length > 0) {
                updateTree($clicked_li.closest('li.directory'))
              } else {
                updateTree($filelist)
              }  
            })
          }

          return false; 
        });
        
        
        $contextMenu.on("click", "a.download", function () {
          // get string list of selected elements
            $selected_items = $filelist.find('li.selected') 
            
            files = []
            $selected_items.each(function() {
              files.push({path:$(this).data('path'), file:$(this).data('file')});
            })

            if (files.length > 0)
              post_to_url('download', 'post', { files: JSON.stringify(files)})
            
            
            $contextMenu.hide();
            return false
        });

        $contextMenu.on("click", "a.delete", function () {
          $contextMenu.hide();

          $selected_items = $filelist.find('li.selected') 
            
          files = []
          $selected_items.each(function() {
            files.push({path:$(this).data('path'), file:$(this).data('file')});
          })
          
          if (files.length > 0) {
            if (confirm($filelist.data('confirmation'))) {
              $.post('delete', {files: files}, function(errors) {
                updateTree( $filelist);
                if (errors.length > 0) alert(errors)
              })
            }
          }
          
          return false    
        });

        $(document).click(function (e) {
          if (e.which!= 3)
            $contextMenu.hide();
        });
        

        function updateTree($elem) {
          var open_folders = []
          $('li.directory.expanded').each(function() { open_folders.push($(this).data('path'))});
          showTree($elem, false, open_folders);
        }

        // this method is called on the parent element of a folder (base element #files div or the enclosing li representing a folder)
				function showTree($elem, sliding, open_folders) {
          $elem.addClass('wait');

          
					$(".jqueryFileTree.start").remove();
					$.post(o.action, { dir: $elem.data('path') }, function(data) {
            // remove old list
            $elem.find('ul').remove()
            $elem.removeClass('wait').append(data);
						
            if (!sliding) {
              el = $elem.find('ul:hidden').show(); 
            } else {
              $elem.find('ul:hidden').slideDown({ duration: 200 });
            } 
            
            $elem.find('li.directory').each(function() {
              if (open_folders.indexOf($(this).data('path')) > -1) {
                $(this).addClass('expanded')
                $(this).removeClass('collapsed')
                showTree($(this), false, open_folders)
              }
            })
					});
				}
				
        var collection = $();
        var $droptarget = null
        

        // Dragging -------------------------------------------------------------------------------------


        $(document).on('dragenter', function(event) {
            //if (collection.size() === 0) {
            //  $('.dropinfo').show();
            //}
            collection = collection.add(event.target);
        });

        $(document).on('dragleave', function(event) {
            setTimeout(function() {
                collection = collection.not(event.target);
                if (collection.size() === 0) {
                  //$('.dropinfo').hide()
                  $filelist.find('li.directory').removeClass('drop-target')
                  $filelist.removeClass('drop-target')
                }
            }, 1);
        });
        
        $(document).on('dragover', function(e) {
          $filelist.find('li.directory').removeClass('drop-target')
          $filelist.removeClass('drop-target')
          
          if ($(e.target).closest('li.directory').length > 0) {
            $(e.target).closest('li.directory').addClass('drop-target')
            $droptarget = $(e.target).closest('li.directory')
          } else if ($(e.target).closest($filelist).length > 0){
            $filelist.addClass('drop-target')
            $droptarget = $filelist
          } else {
            $droptarget = null
          }
          
          e.stopPropagation();
          e.preventDefault();
          return false;
        })

        $filelist.on('dragstart', 'li', function(e) {
          if (!$(this).hasClass('selected')) {
            $filelist.find('li').removeClass('selected');
            $(this).addClass('selected');
          }
          
          var selected = $filelist.find('li.selected')
          
          e.stopPropagation()
        });

        $(document).on('drop', function(e) {
          if ($droptarget) {
            var files = e.originalEvent.dataTransfer.files;
            if (files.length > 0) {
              handleFileUpload(files, $droptarget);
            } else {
              target_path = $droptarget.data('path')
              
              files = []
              $filelist.find('li.selected').each(function() {
                files.push({path:$(this).data('path'), file:$(this).data('file')});
              })
          
              if (files.length > 0) {
                $.post('move', {files: files, target_path:target_path}, function(errors) {
                  updateTree($filelist);
                })
              }
            }
          }

          $filelist.find('li.directory').removeClass('drop-target')
          $filelist.removeClass('drop-target')
          
          collection = $();
          e.stopPropagation();
          e.preventDefault();
          return false;
        });


        // << Dragging ----------------------------------------------------------------------
        
        $('#upload_form').on("submit", function(data){
          selected = $filelist.find('li.selected')
          if (selected.length == 1) {
            $('#upload_form #path').val(selected.data('path'))
          }  
        });

        // Loading message
				$filelist.html('<ul class="jqueryFileTree start"><li class="wait">' + o.loadMessage + '<li></ul>');
				
        // Get the initial file list
        updateTree( $filelist);
			});
		}
	});
	
})(jQuery);