# todo remove this later
$ ->
  console.log "test"
  s = $('html')[0].innerHTML
  arr = s.match(/"translation missing: (.*?)"/gi)
  if arr
    arr = arr.map (s) -> s.slice(22, -1)
    arr.forEach (s) ->
      console.log s
      $('body').prepend(s+"<br/>")
  