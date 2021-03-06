class Tetrus.GameController extends Batman.Controller
  routingKey: 'game'

  constructor: ->
    super
    @iceServers = ['stun:stun.l.google.com:19302']

  play: ->
    @peer = new Tetrus.Peer(Tetrus.get('peer'))
    @game = new Tetrus.Game

    @connectionParams = [
      { DtlsSrtpKeyAgreement: true }
    ]

    if @peer.get('session').type == 'rtp'
      @connectionParams.push { RtpDataChannels: true }

    else if @peer.get('session').type != 'sctp'
      console.error "Invalid connection type", @peer.get('session').type
      Tetrus.Flash.error("Invalid connection type")
      return

    @set('isServer', @peer.get('isServer'))
    @_negotiate()

  start: ->
    @pollForTimeout()
    @game.create()

    @game.player.on 'piece:change', =>
      piece = @game.player.piece
      storage = piece.storageWithAlpha(Tetrus.Piece.peerAlpha)
      @send(type: 'piece:update', piece: { storage: storage, position: piece.position, width: piece.width, height: piece.height })

    @game.player.on 'piece:move', =>
      @send(type: 'piece:move', piece: { position: @game.player.piece.position })

    @game.on 'piece:place', =>
      if @isServer
        @send(type: 'board:update', board: { storage: @game.board.storage })
      else
        piece = @game.player.piece
        @send(type: 'piece:place', piece: { storage: piece.storage, position: piece.position, width: piece.width, height: piece.height })

    @game.on 'game:over', =>
      @send(type: 'game:lose')
      @stop()
      setTimeout(@disconnect, 5000)

    $(document).on('keydown.game', @keydown).on('keyup.game', @keyup)

    @game.player.setNextPiece()
    @game.fire('game:ready')
    @game.start()

  stop: ->
    @game.stop()
    $(document).off('keydown.game').off('keyup.game')

  disconnect: =>
    @set('connecting', false)
    @set('connected', false)
    @peerChannel?.close()
    @peerConnection?.close()
    delete @peerChannel
    delete @peerConnection

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
      when "board:update"
        @game.board.apply(message.board)
      when "piece:update"
        @game.peer.piece.apply(message.piece)
      when "piece:move"
        @game.peer.piece.position = message.piece.position
      when "piece:place"
        piece = new Tetrus.Piece
        piece.apply(message.piece)
        @game.placePiece(piece)
      when "score"
        @game.speed += message.deltaSpeed
        @game.score += message.deltaScore
        @game.board.removeLine(line) for line in message.lines
      when "game:lose"
        @game.lose()
      else
        console.error(message)
        Tetrus.Flash.error("Communication Error")
        @disconnect()

    return

  send: (message) ->
    try
      @peerChannel.send(JSON.stringify(message))
    catch
      Tetrus.Flash.error("Communication Error")
      @stop()
      @disconnect()

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

  keydown: (event) => event.preventDefault() unless @game.keys.keyEvent(event.keyCode, true)
  keyup: (event) => event.preventDefault() unless @game.keys.keyEvent(event.keyCode, false)

  _bindPeerChannel: (channel) ->
    @peerChannel = channel

    channel.onmessage = (event) => @_onMessage(event)

    channel.onopen = =>
      Batman.developer.log("peer channel opened with protocol", channel.protocol)
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

    iceServers = ({ url: x } for x in @iceServers)
    @peerConnection = new RTCPeerConnection({iceServers}, {optional: @connectionParams})
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
      , (err) =>
        Tetrus.Flash.error("Failed to negotiate connection")
        @disconnect()

    Tetrus.on 'socket:message', @_onServerMessage = (message) =>
      setRemoteDescription = =>
        description = new RTCSessionDescription(message.description)
        @peerConnection.setRemoteDescription(description)
        Batman.developer.log("remote sdp", description.sdp)

      if @connecting
        switch message.type
          when "peer:offer"
            setRemoteDescription()

            @peerConnection.createAnswer (description) =>
              @peerConnection.setLocalDescription(description)
              Batman.developer.log("local sdp", description.sdp)
              Tetrus.conn.sendJSON(command: 'peer:answer', description: description)
            , (err) =>
              Tetrus.Flash.error("Failed to negotiate connection")
              @disconnect()

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

      switch message.type
        when "game:ended"
          if message.reason
            Tetrus.Flash.message(message.reason)
          @disconnect()

