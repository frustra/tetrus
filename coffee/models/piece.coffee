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
          @storage[(x + y * @width) * 4 + 3] = (if pieces[piecenum][y][x] then (if peer then 200 else 255) else 0)

  rotate: (times) ->
    newstorage = (x for x in @storage)
    newwidth = @width
    newheight = @height
    for i in [0...times] by 1
      tmpstorage = new Array(newstorage.length)
      for x in [0...newwidth] by 1
        for y in [0...newheight] by 1
          tmpstorage[(newheight - y - 1 + x * newheight) * 4] = newstorage[(x + y * newwidth) * 4]
          tmpstorage[(newheight - y - 1 + x * newheight) * 4 + 1] = newstorage[(x + y * newwidth) * 4 + 1]
          tmpstorage[(newheight - y - 1 + x * newheight) * 4 + 2] = newstorage[(x + y * newwidth) * 4 + 2]
          tmpstorage[(newheight - y - 1 + x * newheight) * 4 + 3] = newstorage[(x + y * newwidth) * 4 + 3]
      newstorage = (x for x in tmpstorage)
      tmp = newwidth
      newwidth = newheight
      newheight = tmp

    deltaX = @width - newwidth
    deltaY = 0 # Math.floor(newheight / 2 - @height / 2)

    collide = -> Tetrus.get('controllers.game').game.collide(arguments...)

    unless collide(newstorage, @position.x + deltaX, @position.y + deltaY, newwidth, newheight)
      @storage = newstorage
      @width = newwidth
      @height = newheight
      @position.x += deltaX
      @position.y += deltaY
    else
      radius = 2
      for dy in [0..radius] by 1
        for dx in [0..radius] by 1
          continue if dx == 0 and dy == 0

          setStorage = (dx, dy) ->
            @storage = newstorage
            @width = newwidth
            @height = newheight
            @position.x += deltaX + dx
            @position.y += deltaY + dy

          unless collide(newstorage, @position.x + deltaX + dx, @position.y + deltaY - dy, newwidth, newheight)
            return setStorage(dx, -dy)
          unless collide(newstorage, @position.x + deltaX - dx, @position.y + deltaY - dy, newwidth, newheight)
            return setStorage(-dx, -dy)
          unless dy == 0
            unless collide(newstorage, @position.x + deltaX + dx, @position.y + deltaY + dy, newwidth, newheight)
              return setStorage(dx, dy)
            unless collide(newstorage, @position.x + deltaX - dx, @position.y + deltaY + dy, newwidth, newheight)
              return setStorage(-dx, dy)

  apply: (piece) ->
    @storage = piece.storage
    @position = piece.position
    @width = piece.width
    @height = piece.height
