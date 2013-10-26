class Tetrus.LandingController extends Batman.Controller
  routingKey: 'landing'

  index: ->
    Tetrus.reset()

    if !window.WebSocket?
      @set('fatal', 'your browser does not support websockets')

    if !window.webrtcCompatible
      @set('fatal', 'your browser does not support webrtc')

  continue: ->
    Tetrus.on 'socket:error', @_socketErrorHandler = (err) =>
      $('#username-error').stop(true).css(opacity: 0).animate(opacity: 1, 200).delay(2500).animate(opacity: 0, 800)
      @set('error', err)

    Tetrus.on 'socket:connected', @_socketConnectedHandler = =>
      Tetrus.off 'socket:error', @_socketErrorHandler
      Tetrus.off 'socket:connected', @_socketConnectedHandler

      Tetrus.attachGlobalErrorHandler()
      Batman.redirect('/lobby')

    Tetrus.setup()

