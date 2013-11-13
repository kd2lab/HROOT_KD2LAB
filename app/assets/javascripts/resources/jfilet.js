
// todo rename this file

if(jQuery) (function($){
	$.extend($.fn, {
		fileTree: function(o, h) {
			// Defaults todo remove unneeded
			if( !o ) var o = {};
			if( o.root == undefined ) o.root = '/';
			if( o.action == undefined ) o.action = 'filelist';
			if( o.folderEvent == undefined ) o.folderEvent = 'click';
			if( o.expandSpeed == undefined ) o.expandSpeed= 200;
			if( o.collapseSpeed == undefined ) o.collapseSpeed= 200;
			if( o.multiFolder == undefined ) o.multiFolder = true;
			if( o.loadMessage == undefined ) o.loadMessage = 'Loading...';
			
			$(this).each( function() {
        function handleFileUpload(files, fileListElem) {
           for (var i = 0; i < files.length; i++) {        
                var size = parseInt(files[i].size/1024);        
                var sizeStr = (size > 1024) ? (size/1024).toFixed(2)+" MB" : size.toFixed(2)+" KB"        
        
                var $elem = $('<div class="statusbar">')
                             .append($('<div class="filename">').html(files[i].name))
                             .append($('<div class="filesize">').html(sizeStr))
                             .append('<div class="progress progress-striped active"><div class="bar" style="width: 1%;"></div></div>')
                             .append('<div class="abort-button"><a class="btn btn-danger btn-mini">Stop</a></div></div>')
                             .insertAfter(fileListElem)
              
                formData = new FormData();
                formData.append('file', files[i]);
              
                var jqXHR=$.ajax({
                    $elem: $elem, 
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
                        console.log(data)
                        this.$elem.children('.progress').removeClass('active');
                        this.$elem.delay(5000).fadeOut(1000, function() { $(this).remove() })
                        
                        // reload full tree
                        showTree( fileListElem, escape(o.root) );
                    }
                });
                
                console.log($elem.find('.abort-button a'))
                $elem.find('.abort-button a').click(function() {
                  console.log(jqXHR);
                  jqXHR.abort();
                  $(this).closest('.statusbar').remove()
                })
           }
        }
				
        
        
				function showTree(elem, path) {
          $(elem).addClass('wait');
					$(".jqueryFileTree.start").remove();
					$.post(o.action, { dir: path }, function(data) {
            $(elem).find('ul').remove()
            $(elem).removeClass('wait').append(data);
						if( o.root == path ) 
              $(elem).find('ul:hidden').show(); 
            else {
              $(elem).find('ul:hidden').slideDown({ duration: o.expandSpeed });
            } 
						bindTree(elem);
					});
				}
				
				function bindTree(t) {
					$(t).find('LI A').bind(o.folderEvent, function() {
						if( $(this).parent().hasClass('directory') ) {
							if( $(this).parent().hasClass('collapsed') ) {
								// Expand
								if( !o.multiFolder ) {
									$(this).parent().parent().find('UL').slideUp({ duration: o.collapseSpeed });
									$(this).parent().parent().find('LI.directory').removeClass('expanded').addClass('collapsed');
								}
								$(this).parent().find('UL').remove(); // cleanup
								showTree( $(this).parent(), escape($(this).attr('rel').match( /.*\// )) );
								$(this).parent().removeClass('collapsed').addClass('expanded');
							} else {
								// Collapse
								$(this).parent().find('UL').slideUp({ duration: o.collapseSpeed });
								$(this).parent().removeClass('expanded').addClass('collapsed');
							}
						} else {
							h($(this).attr('rel'));
						}
						return false;
					});
					// Prevent A from triggering the # on non-click events
					if( o.folderEvent.toLowerCase != 'click' ) $(t).find('LI A').bind('click', function() { return false; });
				}
				
        var collection = $();

        $(document).on('dragenter', function(event) {
            if (collection.size() === 0) {
              $('#dropzone').show();
              $('#dropzone').height($('#files').height());
              $('#dropzone').width($('#files').width());
              
            }
            collection = collection.add(event.target);
        });

        $(document).on('dragleave', function(event) {
            setTimeout(function() {
                collection = collection.not(event.target);
                console.log(collection.size())
                if (collection.size() === 0) {
                  $('#dropzone').hide()
                }
            }, 1);
        });
        
        $(document).on('dragover', function(e) {
          e.stopPropagation();
          e.preventDefault();
          return false;
        })
          
        $(document).on('drop', function(e) {
          if ($(e.target).closest("#dropzone").length > 0) {
            var files = e.originalEvent.dataTransfer.files;
            handleFileUpload(files,$('#files'));
          }
          $('#dropzone').hide();
          collection = $();
          console.log(e)
          e.stopPropagation();
          e.preventDefault();
          return false;
        });
        
        // Loading message
				$(this).html('<ul class="jqueryFileTree start"><li class="wait">' + o.loadMessage + '<li></ul>');
				
        // Get the initial file list
        showTree( $(this), escape(o.root) );
			});
		}
	});
	
})(jQuery);