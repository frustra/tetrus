Tetrus.Flash = Batman
  _message: ""
  _class: "message"

  _flash: (message) ->
    @set('_message', message)
    node = $('#flash')
    bottom = node.css('bottom')
    node.animate(bottom: 0, 200).delay(5000).animate({bottom}, 800)

  message: (message) ->
    @set('_class', 'message')
    @_flash(message)

  error: (error) ->
    @set('_class', 'error')
    @_flash(error)

