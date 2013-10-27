class Tetrus.Board
  constructor: ->
    @storage = new Array(10 * 20 * 4)

  @get: (x, y) ->
    offset = (x + y * 10) * 4
    r: @storage[offset]
    g: @storage[offset + 1]
    b: @storage[offset + 2]
    a: @storage[offset + 3]

  @set: (x, y, color) ->
    offset = (x + y * 10) * 4
    @storage[offset] = color.r
    @storage[offset + 1] = color.g
    @storage[offset + 2] = color.b
    @storage[offset + 3] = color.a

  @removeLine: (y) ->
    endIndex = ((y + 1) * 40 - 4)
    for i in [endIndex..0] by -1
      if i >= 40
        @storage[i] = @storage[i - 40]
      else
        @storage[i] = 0
    return

  apply: (board) ->
    @storage = board

