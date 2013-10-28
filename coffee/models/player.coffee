class Tetrus.Player extends Batman.Object
  constructor: (peer) ->
    @piece = @nextPiece = new Tetrus.Piece(peer)

  setNextPiece: ->
    if @piece
      @piece.off('change')
      @piece.off('move')

    @piece = @nextPiece
    @nextPiece = new Tetrus.Piece()
    @piece.position.x = 5 - Math.floor(@piece.width / 2)
    @piece.position.y = 0

    @piece.on('change', => @fire('piece:change'))
    @piece.on('move', => @fire('piece:move'))
    @fire('piece:change')

class Tetrus.PeerPlayer extends Tetrus.Player
  constructor: ->
    super(true)

