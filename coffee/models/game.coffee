class Tetrus.Game
  constructor: ->
    @board = new Tetrus.Board
    @player = new Tetrus.Player
    @peer = new Tetrus.Player(true)
    @score = 0
    @speed = 750

  loop: =>
    ctrl = Tetrus.get('controllers.game')
    piece = @player.piece
    ctrl.send(type: 'piece', piece: { storage: piece.storage, position: piece.position, width: piece.width, height: piece.height })

    setTimeout(@loop, 50)

  fall: ->
    @collide()
    @player.piece.position.y++

  fallLoop: =>
    @fall()
    setTimeout(@fallLoop, @speed)

  move: (dx) ->
    pos = @player.piece.position
    if pos.x + dx >= 0 and pos.x + dx < @board.width - @player.piece.width + 1
      pos.x += dx

  collide: ->
    {x, y} = @player.piece.position
    false

