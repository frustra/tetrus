class Tetrus.Game
  constructor: ->
    @board = new Tetrus.Board
    @player = new Tetrus.Player
    @peer = new Tetrus.Player
    @score = 0
    @speed = 750

  loop: ->

  fall: ->
    @collide()
    @player.piece.position.y++
    console.log 'fall'

  fallLoop: =>
    @fall()
    setTimeout(fallLoop, @speed)

  move: (dx) ->
    pos = @player.piece.position
    if pos.x + dx >= 0 and pos.x + dx < @board.width
      pos.x += dx

  collide: ->
    {x, y} = @player.piece.position

