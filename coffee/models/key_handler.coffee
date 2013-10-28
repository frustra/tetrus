class Tetrus.KeyHandler
  constructor: (@game) ->

  process: ->
    @game.fall() if @_down

  left: (pressed) ->
    @game.player.piece.move(-1, 0, @game.board) if pressed

  right: (pressed) ->
    @game.player.piece.move(1, 0, @game.board) if pressed

  down: (pressed) -> @_down = pressed

  space: (pressed) -> @game.drop() if pressed

  x: (pressed) -> @game.player.piece.rotate(1, @game.board) if pressed
  z: (pressed) -> @game.player.piece.rotate(3, @game.board) if pressed

