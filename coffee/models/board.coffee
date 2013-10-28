class Tetrus.Board
  constructor: ->
    @width = 10
    @height = 20
    @storage = new Array(@width * @height * 4)

  get: (x, y) ->
    offset = (x + y * @width) * 4
    r: @storage[offset]
    g: @storage[offset + 1]
    b: @storage[offset + 2]
    a: @storage[offset + 3]

  set: (x, y, color) ->
    offset = (x + y * @width) * 4
    @storage[offset] = color.r
    @storage[offset + 1] = color.g
    @storage[offset + 2] = color.b
    @storage[offset + 3] = color.a

  removeLine: (y) ->
    endIndex = ((y + 1) * @width * 4 - 1)
    for i in [endIndex..0] by -1
      if i >= @width * 4
        @storage[i] = @storage[i - @width * 4]
      else
        @storage[i] = 0
    return

  collide: (storage, x, y, width, height) ->
    if x < 0 or y < 0 or x + (width - 1) >= @width or y + (height - 1) >= @height
      return true

    for dx in [0...width] by 1
      for dy in [0...height] by 1
        if storage[(dx + dy * width) * 4 + 3] > 0
          return true if @storage[(x + dx + (y + dy) * @width) * 4 + 3] > 0

    return false

  place: (piece) ->
    for x in [0...piece.width] by 1
      for y in [0...piece.height] by 1
        if piece.storage[(x + y * piece.width) * 4 + 3] > 0
          targetOffset = (piece.position.x + x + (piece.position.y + y) * @width) * 4
          sourceOffset = (x + y * piece.width) * 4
          if @storage[targetOffset + 3] > 0
            @storage[targetOffset] = piece.storage[sourceOffset] * 0.5 + @storage[targetOffset] * 0.5
            @storage[targetOffset + 1] = piece.storage[sourceOffset + 1] * 0.5 + @storage[targetOffset + 1] * 0.5
            @storage[targetOffset + 2] = piece.storage[sourceOffset + 2] * 0.5 + @storage[targetOffset + 2] * 0.5
          else
            @storage[targetOffset] = piece.storage[sourceOffset]
            @storage[targetOffset + 1] = piece.storage[sourceOffset + 1]
            @storage[targetOffset + 2] = piece.storage[sourceOffset + 2]
          @storage[targetOffset + 3] = 255

    return

  apply: (board) ->
    @storage = board.storage

