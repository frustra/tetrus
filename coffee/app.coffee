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
    @stopKeepAlive()
    if @conn
      @conn.close()
      delete @conn

    @set('username', '')
    @set('peerHash', new Batman.Hash)

    @off('socket:error')
    @off('socket:connected')
    @off('socket:message')

  @setup: (ready) ->
    @conn = new WebSocket("ws://#{@get('hostAddr')}/play_socket?username=#{encodeURIComponent(@get('username'))}&browser=#{webrtcDetectedBrowser}&version=#{webrtcDetectedVersion}")

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
          @startKeepAlive()
        else if message.type == 'pong'
        else
          @fire('socket:message', message)

      onopen: => @fire('socket:opened')
      onclose: (event) => @fire('socket:error', 'Lost Connection')
      onerror: (event) => @fire('socket:error', 'Unexpected Error')

  @play: (invite) ->
    @set('peer', username: invite.get('username'), isServer: invite.get('isServer'), session: invite.get('session'))
    Batman.redirect('/play')

  @attachGlobalErrorHandler: ->
    @on 'socket:error', (err) =>
      Tetrus.Flash.error(err)
      @reset()
      Batman.redirect('/')

  @startKeepAlive: ->
    @_keepAliveInterval = setInterval =>
      @conn?.sendJSON(command: 'ping')
    , 15 * 1000

  @stopKeepAlive: ->
    clearInterval(@_keepAliveInterval) if @_keepAliveInterval

$ ->
  $('body').addClass("webrtc-#{webrtcDetectedBrowser}")
  Tetrus.set('hostAddr', window.location.host)
  Tetrus.reset()
  Tetrus.run()

