class Tetrus.Game
  constructor: ->
    @board = new Tetrus.Board
    @player = new Tetrus.Player
    @peer = new Tetrus.Player
    @score = 0
    @speed = 750

  loop: ->

  fallLoop: =>
    @player.piece.y++
    @collide()

    setTimeout(fallLoop, @speed)

  collide: ->
    {x, y} = @player.piece.position

