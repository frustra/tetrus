colors = [
  r: 0, g: 255, b: 0
  r: 102, g: 204, b: 255
  r: 255, g: 0, b: 0
  r: 0, g: 0, b: 255
  r: 204, g: 0, b: 255
  r: 255, g: 102, b: 0
  r: 255, g: 255, b: 0
]
pieces = [
  [
    [true, true, false]
    [false, true, true]
  ]
  [
    [false, true, true]
    [true, true, false]
  ]
  [
    [true, true]
    [true, true]
  ]
  [
    [false, false, true]
    [true, true, true]
  ]
  [
    [true, false, false]
    [true, true, true]
  ]
  [
    [true, true, true, true]
  ]
  [
    [false, true, false]
    [true, true, true]
  ]
]

class Tetrus.Piece
  constructor: (peer, @storage) ->
    @position = x: 0, y: 0
    @width = 0
    @height = 0
    unless @storage
      piecenum = Math.floor(Math.random() * 7)
      @width = pieces[piecenum][0].length
      @height = pieces[piecenum].length
      @storage = new Array(@width * @height * 4)
      for x in [0...@width] by 1
        for y in [0...@height] by 1
          @storage[(x + y * @boardWidth) * 4] = colors[piecenum].r
          @storage[(x + y * @boardWidth) * 4 + 1] = colors[piecenum].g
          @storage[(x + y * @boardWidth) * 4 + 2] = colors[piecenum].b
          @storage[(x + y * @boardWidth) * 4 + 3] = (if pieces[piecenum][y][x] then (if peer then 100 else 255) else 0)

  rotate: (times) ->
    newstorage = new Array(@storage.length)
    for (int x = 0; x < @width; x++) {
      for (int y = 0; y < @height; y++) {
        if (currPiece[x][y]) tmpPiece[currPiece[x].length - y - 1][x] = true;
      }
    }
    int newX = (int) ((currPiece.length / 2.0) - (tmpPiece.length / 2.0));
    int newY = (int) ((tmpPiece.length / 2.0) - (currPiece.length / 2.0));
    if (!collideBlock(tmpPiece, currX + newX, currY + newY)) {
      currPiece = tmpPiece;
      currX += newX;
      currY += newY;
    } else {
      int radius = 2;
      for (int yOff = 0; yOff >= -radius; yOff--) {
        for (int xOff = 1; xOff <= radius; xOff++) {
          if (!collideBlock(tmpPiece, currX + newX + xOff, currY + newY - yOff)) {
            currPiece = tmpPiece;
            currX += newX + xOff;
            currY += newY - yOff;
            return;
          }
          if (!collideBlock(tmpPiece, currX + newX - xOff, currY + newY - yOff)) {
            currPiece = tmpPiece;
            currX += newX - xOff;
            currY += newY - yOff;
            return;
          }
          if (yOff != 0) {
            if (!collideBlock(tmpPiece, currX + newX + xOff, currY + newY + yOff)) {
              currPiece = tmpPiece;
              currX += newX + xOff;
              currY += newY + yOff;
              return;
            }
            if (!collideBlock(tmpPiece, currX + newX - xOff, currY + newY + yOff)) {
              currPiece = tmpPiece;
              currX += newX - xOff;
              currY += newY + yOff;
              return;
            }
          }
        }
      }
    }

  apply: (piece) ->
    @storage = piece.storage
    @position = piece.position
