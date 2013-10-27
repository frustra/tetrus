class Tetrus.Game
  constructor: ->
    @board = new Tetrus.Board
    @player = new Tetrus.Player
    @peer = new Tetrus.Player
    @score = 0
    @speed = 7

