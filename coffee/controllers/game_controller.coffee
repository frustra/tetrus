class Tetrus.GameController extends Batman.Controller
  routingKey: 'game'

  play: ->
    @peer = new Tetrus.Peer(Tetrus.get('peer'))
    @set('isServer', @peer.get('isServer'))
    @_negotiate()

  start: ->
    @pollForTimeout()
    @game = new Tetrus.Game

    @keys = {}
    Batman.DOM.addEventListener(document, 'keydown', @keydown)
    Batman.DOM.addEventListener(document, 'keyup', @keydown)

  disconnect: ->
    @set('connecting', false)
    @set('connected', false)
    delete @peerChannel
    delete @peerConnection

    Batman.DOM.removeEventListener(document, 'keydown', @keydown)
    Batman.DOM.removeEventListener(document, 'keyup', @keydown)

    if @_onMessage
      Tetrus.off 'socket:message', @_onMessage
      delete @_onMessage

    Tetrus.conn.sendJSON(command: 'game:end')
    Batman.redirect('/lobby')

  _onMessage: (event) ->
    @lastResponse = new Date().getTime()
    message = JSON.parse(event.data)
    #console.log(message)

    switch message.type
      when "ping"
        @send(type: 'pong', timeStamp: event.timeStamp)
      when "pong"
        @set('rtt', event.timeStamp - message.timeStamp)
      when "board"
        @game.board.apply(message.board)
      when "piece"
        @game.peerPiece.apply(message.piece)
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
      if @lastResponse < lastCheck
        Tetrus.Flash.error("Connection timed out")
        @disconnect()
      else
        lastCheck = new Date().getTime()
        @send(type: 'ping')
        setTimeout check, 2000

    check()

  _setKey: (keyCode, pressed) ->
    switch event.keyCode
      when 37
        @keys.left = pressed
      when 38
        @keys.up = pressed
      when 39
        @keys.right = pressed
      when 40
        @keys.down = pressed
      when 32
        @keys.space = pressed

  keydown: (event) => @_setKey(event.keyCode, true)
  keyup: (event) => @_setKey(event.keyCode, false)

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

    @peerConnection = new RTCPeerConnection({iceServers: [url: 'stun:stun.l.google.com:19302']}, {optional: [RtpDataChannels: true]})
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

    Tetrus.on 'socket:message', @_onMessage = (message) =>
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

