class Tetrus.Game
  constructor: ->
    @board = new Tetrus.Board
    @piece = new Tetrus.Piece
    @peerPiece = new Tetrus.Piece
    @score = 0
    @speed = 7

