class Tetrus.LobbyController extends Batman.Controller
  routingKey: 'lobby'

  index: ->
    @set('receivedInvites', new Batman.Hash)

    if !Tetrus.get('username')
      Tetrus.redirectWindow('/')
    else
      Tetrus.conn.sendJSON(command: 'fetch')

    @_attachSocketListeners()

  _onMessage: (message) ->
    switch message.type
      when "player:joined"
        Tetrus.get('peerHash').set(message.player.username, message.player)

      when "player:left"
        @get('receivedInvites').unset(message.player.username)
        if @get('sentInvite.username') is message.player.username
          @unset('pending')
          @unset('sentInvite')
        Tetrus.get('peerHash').unset(message.player.username)

      when "invite:accepted"
        @unset('pending')
        Tetrus.play(@unset('sentInvite'))

      when "invite:rejected"
        Tetrus.Flash.message("#{@sentInvite.get('username')} rejected your invitation")
        @unset('pending')
        @unset('sentInvite')

      when "invite:received"
        @get('receivedInvites').set(message.invite.username, invite = new Tetrus.Invite(message.invite))
        Tetrus.Flash.message("Got invitation from #{message.invite.username}")

      when "invite:cancelled"
        @get('receivedInvites').unset(message.invite.username)
        Tetrus.Flash.message("#{message.invite.username} cancelled their invitation")

  _attachSocketListeners: ->
    Tetrus.on 'socket:message', @_boundOnMessage = @_onMessage.bind(this)

  @accessor 'peers', ->
    Tetrus.get('peerHash').map (_, value) -> value

  @accessor 'invitesSet', ->
    @get('receivedInvites').map (_, value) -> value

  sendInvite: (node, event, view) ->
    if @get('pending')
      Tetrus.Flash.message('You still have a pending invitation')
    else
      @set('sentInvite', new Tetrus.Invite(username: view.get('peer').username, isSource: true)).send()
      @set('pending', true)

  cancelInvite: (node, event, view) ->
    if @get('sentInvite')
      @unset('sentInvite').cancel()
      @set('pending', false)

  acceptInvite: (node, event, view) ->
    invite = view.get('invite')

    @get('receivedInvites').unset(invite.get('username'))
    @get('receivedInvites').forEach (invite) -> invite.reject()
    invite.accept()
    Tetrus.play(invite)

  rejectInvite: (node, event, view) ->
    invite = view.get('invite')

    @get('receivedInvites').unset(invite.get('username'))
    invite.reject()

