class Tetrus.Piece
  constructor: ->
    @position = x: 0, y: 0
    @width = 0
    @height = 0
    @storage = []

  rotate: (direction) ->
    storage = []

  apply: (piece) ->
    @storage = piece.storage
    @position = piece.position

