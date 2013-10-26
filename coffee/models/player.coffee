class Tetrus.Player
  constructor: (peer) ->
    @nextPiece = new Tetrus.Piece(peer) unless peer
    @piece = new Tetrus.Piece(peer)

  setNextPiece: ->
    @piece = @nextPiece
    @nextPiece = new Tetrus.Piece()
    @piece.position.x = 5 - (@piece.width / 2)
    @piece.position.y = 0

