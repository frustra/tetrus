class Tetrus.Invite extends Batman.Model
  _sendCommand: (command) ->
    Tetrus.conn.sendJSON(command: "invite:#{command}", username: @get('username'))

  for x in ['accept', 'reject', 'send', 'cancel']
    do (x) => @::[x] = -> @_sendCommand(x)

