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
  @playerAlpha = 255
  @peerAlpha = 200

  constructor: (peer, @storage) ->
    @position = x: 0, y: 0
    @width = 0
    @height = 0
    unless @storage
      index = Math.floor(Math.random() * 7)
      piece = pieces[index]
      @height = piece.length
      @width = piece[0].length

      alpha = (if peer then @constructor.peerAlpha else @constructor.playerAlpha)

      @storage = new Array(@width * @height * 4)
      for x in [0...@width] by 1
        for y in [0...@height] by 1
          offset = (x + y * @width) * 4
          {r, g, b} = colors[index]
          @storage[offset] = r
          @storage[offset + 1] = g
          @storage[offset + 2] = b
          @storage[offset + 3] = (if piece[y][x] then alpha else 0)

  rotate: (times) ->
    storage = (x for x in @storage)
    width = @width
    height = @height
    for i in [0...times] by 1
      targetStorage = new Array(storage.length)
      for x in [0...width] by 1
        for y in [0...height] by 1
          sourceOffset = (x + y * width) * 4
          targetOffset = (height - y - 1 + x * height) * 4
          targetStorage[targetOffset] = storage[sourceOffset]
          targetStorage[targetOffset + 1] = storage[sourceOffset + 1]
          targetStorage[targetOffset + 2] = storage[sourceOffset + 2]
          targetStorage[targetOffset + 3] = storage[sourceOffset + 3]

      storage = (x for x in targetStorage)
      tmp = width
      width = height
      height = tmp

    deltaX = @width - width
    deltaY = 0 # Math.floor(height / 2 - @height / 2)

    game = Tetrus.get('controllers.game').game

    setStorage = (dx, dy) =>
      @storage = storage
      @width = width
      @height = height
      @position.x += deltaX + dx
      @position.y += deltaY + dy

    unless game.collide(storage, @position.x + deltaX, @position.y + deltaY, width, height)
      setStorage(0, 0)
    else
      radius = 2
      for dy in [0..radius] by 1
        for dx in [0..radius] by 1
          continue if dx == 0 and dy == 0
          unless game.collide(storage, @position.x + deltaX + dx, @position.y + deltaY - dy, width, height)
            return setStorage(dx, -dy)
          unless game.collide(storage, @position.x + deltaX - dx, @position.y + deltaY - dy, width, height)
            return setStorage(-dx, -dy)
          unless dy == 0
            unless game.collide(storage, @position.x + deltaX + dx, @position.y + deltaY + dy, width, height)
              return setStorage(dx, dy)
            unless game.collide(storage, @position.x + deltaX - dx, @position.y + deltaY + dy, width, height)
              return setStorage(-dx, dy)

  apply: (piece) ->
    @storage = piece.storage
    @position = piece.position
    @width = piece.width
    @height = piece.height

