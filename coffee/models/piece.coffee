colors = [
  {r: 0, g: 255, b: 0}
  {r: 102, g: 204, b: 255}
  {r: 255, g: 0, b: 0}
  {r: 0, g: 0, b: 255}
  {r: 204, g: 0, b: 255}
  {r: 255, g: 102, b: 0}
  {r: 255, g: 255, b: 0}
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
          @storage[(x + y * @width) * 4] = colors[piecenum].r
          @storage[(x + y * @width) * 4 + 1] = colors[piecenum].g
          @storage[(x + y * @width) * 4 + 2] = colors[piecenum].b
          @storage[(x + y * @width) * 4 + 3] = (if pieces[piecenum][y][x] then (if peer then 100 else 255) else 0)

  rotate: (times) ->
    for i in [0...times] by 1
      newstorage = new Array(@storage.length)
      for x in [0...@width] by 1
        for y in [0...@height] by 1
          newstorage[(@height - y - 1 + x * @width) * 4] = @storage[(x + y * @width) * 4]
          newstorage[(@height - y - 1 + x * @width) * 4 + 1] = @storage[(x + y * @width) * 4 + 1]
          newstorage[(@height - y - 1 + x * @width) * 4 + 2] = @storage[(x + y * @width) * 4 + 2]
          newstorage[(@height - y - 1 + x * @width) * 4 + 3] = @storage[(x + y * @width) * 4 + 3]
      @storage = newstorage
      tmp = @width
      @width = @height
      @height = tmp

  apply: (piece) ->
    @storage = piece.storage
    @position = piece.position
