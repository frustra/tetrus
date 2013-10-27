Tetrus.Flash = Batman
  message: (message) ->
    @set('_class', 'message')
    @_flash(message)

  error: (error) ->
    @set('_class', 'error')
    @_flash(error)

  open: -> $('#flash').animate(bottom: 0, 200)
  close: -> $('#flash').animate(bottom: @_bottom, 800)

  _flash: (message) ->
    clearTimeout(@_closeTimeout) if @_closeTimeout
    @_closeTimeout = setTimeout(@close.bind(this), 5000)

    @_bottom ?= $('#flash').css('bottom')
    @set('_message', message)
    @open()

