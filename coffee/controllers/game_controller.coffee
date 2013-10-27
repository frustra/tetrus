class Tetrus.GameController extends Batman.Controller
  routingKey: 'game'

  play: ->
    @peer = new Tetrus.Peer(Tetrus.get('peer'))
    @game = new Tetrus.Game
    @set('isServer', @peer.get('isServer'))
    @_negotiate()

  start: ->
    @pollForTimeout()
    console.log 'Started game'
    @game.loop()
    @game.fallLoop()

    @keys = {}
    Batman.DOM.addEventListener(document, 'keydown', @keydown)
    Batman.DOM.addEventListener(document, 'keyup', @keyup)

  disconnect: ->
    @set('connecting', false)
    @set('connected', false)
    delete @peerChannel
    delete @peerConnection

    Batman.DOM.removeEventListener(document, 'keydown', @keydown)
    Batman.DOM.removeEventListener(document, 'keyup', @keydown)

    if @_onServerMessage
      Tetrus.off 'socket:message', @_onServerMessage
      delete @_onServerMessage

    Tetrus.conn.sendJSON(command: 'game:end')
    Batman.redirect('/lobby')

  _onMessage: (event) ->
    @lastResponse = new Date().getTime()
    message = JSON.parse(event.data)

    switch message.type
      when "ping"
        @send(type: 'pong', timeStamp: event.timeStamp)
      when "pong"
        @set('rtt', event.timeStamp - message.timeStamp)
      when "board"
        @game.board.apply(message.board)
      when "piece"
        @game.peer.piece.apply(message.piece)
      when "score"
        @game.speed += message.deltaSpeed
        @game.score += message.deltaScore
        @game.board.removeLine(line) for line in message.lines
      else
        console.error(message)
        Tetrus.Flash.error("Communication Error")
        @disconnect()

  send: (message) ->
    @peerChannel.send(JSON.stringify(message))

  pollForTimeout: ->
    lastCheck = 0
    @lastResponse = new Date().getTime()

    check = =>
      return unless @connected
      if @lastResponse < lastCheck - 500
        Tetrus.Flash.error("Connection timed out")
        @disconnect()
      else
        lastCheck = new Date().getTime()
        setTimeout check, 2000
        @send(type: 'ping')

    check()

  _setKey: (keyCode, pressed) ->
    switch keyCode
      when 37
        if pressed
          repeat = =>
            if @keys.left
              @game.move(-1)
              @keys.lr = setTimeout(repeat, 100)
          @keys.lr = setTimeout(repeat, 150)
          @game.move(-1)
        else
          clearTimeout(@keys.lr)
        @keys.left = pressed
        return true
      when 38
        return true
      when 39
        if pressed
          repeat = =>
            if @keys.right
              @game.move(1)
              @keys.rr = setTimeout(repeat, 100)
          @keys.rr = setTimeout(repeat, 150)
          @game.move(1)
        else
          clearTimeout(@keys.rr)
        @keys.right = pressed
        return true
      when 40
        if pressed
          repeat = =>
            if @keys.down
              @game.fall()
              @keys.dr = setTimeout(repeat, 100)
          @keys.dr = setTimeout(repeat, 150)
          @game.fall()
        else
          clearTimeout(@keys.dr)
        @keys.down = pressed
        return true
      when 32
        @keys.space = pressed
        return true

  keydown: (event) =>
    if @_setKey(event.keyCode, true)
      event.preventDefault()
    switch event.keyCode
      when 88 # x
        @game.player.piece.rotate(1)
        event.preventDefault()
      when 90 # z
        @game.player.piece.rotate(3)
        event.preventDefault()

  keyup: (event) =>
    if @_setKey(event.keyCode, false)
      event.preventDefault()

  _bindPeerChannel: (channel) ->
    @peerChannel = channel

    channel.onmessage = (event) => @_onMessage(event)

    channel.onopen = =>
      Batman.developer.log("peer channel opened")
      @set('connecting', false)
      @set('connected', true)
      @start()

    channel.onclose = =>
      Batman.developer.log("peer channel closed")
      @disconnect()

    channel.onerror = (error) =>
      Batman.developer.log("peer channel errored:", error)
      @disconnect()

  _negotiate: ->
    @set('connecting', true)
    @set('connected', false)

    @peerConnection = new RTCPeerConnection({iceServers: [url: 'stun:stun.l.google.com:19302']}, null)#{optional: [RtpDataChannels: true]})
    candidates = []

    @peerConnection.onicecandidate = (event) =>
      if candidate = event.candidate
        Batman.developer.log("local candidate", candidate.candidate)
        candidates.push(candidate)

    @peerConnection.ondatachannel = (event) => @_bindPeerChannel(event.channel)

    if @isServer
      @_bindPeerChannel(@peerConnection.createDataChannel('RTCDataChannel'))

      @peerConnection.createOffer (description) =>
        @peerConnection.setLocalDescription(description)
        Batman.developer.log("local sdp", description.sdp)
        Tetrus.conn.sendJSON(command: 'peer:offer', description: description, username: @peer.get('username'))
      , null, null

    Tetrus.on 'socket:message', @_onServerMessage = (message) =>
      setRemoteDescription = =>
        description = new RTCSessionDescription(message.description)
        @peerConnection.setRemoteDescription(description)
        Batman.developer.log("remote sdp", description.sdp)

      switch message.type
        when "peer:offer"
          setRemoteDescription()

          @peerConnection.createAnswer (description) =>
            @peerConnection.setLocalDescription(description)
            Batman.developer.log("local sdp", description.sdp)
            Tetrus.conn.sendJSON(command: 'peer:answer', description: description)
          , null, null

        when "peer:answer"
          setRemoteDescription()
          Tetrus.conn.sendJSON(command: 'peer:handshake')

        when "peer:handshake:complete"
          candidates.push = (candidate) ->
            Tetrus.conn.sendJSON(command: 'peer:candidate', candidate: candidate)

          candidates.push(candidate) for candidate in candidates
          candidates.length = 0

        when "peer:candidate"
          candidate = new RTCIceCandidate(message.candidate)
          @peerConnection.addIceCandidate(candidate)
          Batman.developer.log("remote candidate", candidate.candidate)

        when "game:ended"
          @disconnect()

