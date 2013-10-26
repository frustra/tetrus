class Tetrus.GameController extends Batman.Controller
  routingKey: 'game'

  play: ->
    @set('isServer', Tetrus.get('peer.isServer'))
    @_negotiate()

  _onMessage: (event) ->
    console.log(event)

    message = JSON.parse(event.data)
    switch message.type
      when "ping"
        @send(type: 'pong', timeStamp: event.timeStamp)
      when "pong"
        @set('lag', event.timeStamp - message.timeStamp)
        console.log @lag
      else
        console.error(message)
        Tetrus.Flash.error("Communication Error")

  send: (message) ->
    @peerChannel.send(JSON.stringify(message))

  _bindPeerChannel: (channel) ->
    @peerChannel = channel

    channel.onmessage = (event) => @_onMessage(event)

    channel.onopen = =>
      Batman.developer.log("peer channel opened")
      @set('connecting', false)
      @set('connected', true)

    channel.onclose = =>
      Batman.developer.log("peer channel closed")
      @set('connected', false)

    channel.onerror = (error) =>
      Batman.developer.log("peer channel errored:", error)
      @set('connected', false)

  _negotiate: ->
    @set('connecting', true)
    @set('connected', false)

    @peer = new Tetrus.Peer(Tetrus.get('peer'))
    @peerConnection = new RTCPeerConnection({iceServers: [url: 'stun:stun.l.google.com:19302']}, {optional: [RtpDataChannels: true]})
    @candidates = []

    @peerConnection.onicecandidate = (event) =>
      if candidate = event.candidate
        Batman.developer.log("local candidate", candidate.candidate)
        @candidates.push(candidate)

    @peerConnection.ondatachannel = (event) => @_bindPeerChannel(event.channel)

    if @isServer
      @_bindPeerChannel(@peerConnection.createDataChannel('RTCDataChannel'))

      @peerConnection.createOffer (description) =>
        @peerConnection.setLocalDescription(description)
        Batman.developer.log("local sdp", description.sdp)
        Tetrus.conn.sendJSON(command: 'peer:offer', description: description, username: @peer.get('username'))
      , null, null

    Tetrus.on 'socket:message', (message) =>
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
          @candidates.push = (candidate) ->
            Tetrus.conn.sendJSON(command: 'peer:candidate', candidate: candidate)

          @candidates.push(candidate) for candidate in @candidates
          @candidates.length = 0

        when "peer:candidate"
          candidate = new RTCIceCandidate(message.candidate)
          @peerConnection.addIceCandidate(candidate)
          Batman.developer.log("remote candidate", candidate.candidate)

