Batman.extend Batman.config,
  pathToApp: '/'
  pathToHTML: '/html'

Batman.View::cache = false

class window.Tetrus extends Batman.App
  @layout: 'layout'

  @root 'landing#index'
  @route 'lobby', 'lobby#index'
  @route 'play', 'game#play'

  @route '404', 'errors#404'

  @on 'error', (event) ->
    event.preventDefault()
    console.error event
    Tetrus.Flash.error("Unexpected Error")

  @redirectWindow: (location) ->
    window.location = location

  @flash: (message) ->
    console.err(message)

  @reset: ->
    if @conn
      @conn.close()
      delete @conn

    @set('username', '')
    @set('peerHash', new Batman.Hash)

    @off('socket:error')
    @off('socket:connected')
    @off('socket:message')

  @setup: (ready) ->
    @conn = new WebSocket("ws://#{@get('hostAddr')}/play_socket?username=#{encodeURIComponent(@get('username'))}")

    Batman.mixin @conn,
      sendJSON: (obj) ->
        @send(JSON.stringify(obj))

      onmessage: (event) =>
        message = JSON.parse(event.data)
        if message.error
          @fire('socket:error', message.error)
          @reset()
        else if message.type == 'connected'
          @fire('socket:connected')
        else
          @fire('socket:message', message)

      onopen: => @fire('socket:opened')
      onclose: (event) => @fire('socket:error', 'Lost Connection')
      onerror: (event) => @fire('socket:error', 'Unexpected Error')

  @play: (invite) ->
    @set('peer', username: invite.get('username'), isServer: !invite.get('isSource'))
    Batman.redirect('/play')

  @attachGlobalErrorHandler: ->
    @on 'socket:error', (err) =>
      Tetrus.Flash.error(err)

$ ->
  Tetrus.set('hostAddr', window.location.host)
  Tetrus.reset()
  Tetrus.run()

