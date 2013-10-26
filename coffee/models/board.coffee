class Tetrus.Board
  constructor: ->
    @width = 10
    @height = 20
    @storage = new Array(@width * @height * 4)

  @get: (x, y) ->
    offset = (x + y * @width) * 4
    r: @storage[offset]
    g: @storage[offset + 1]
    b: @storage[offset + 2]
    a: @storage[offset + 3]

  @set: (x, y, color) ->
    offset = (x + y * @width) * 4
    @storage[offset] = color.r
    @storage[offset + 1] = color.g
    @storage[offset + 2] = color.b
    @storage[offset + 3] = color.a

  @removeLine: (y) ->
    endIndex = ((y + 1) * @width * 4 - 4)
    for i in [endIndex..0] by -1
      if i >= @width * 4
        @storage[i] = @storage[i - @width * 4]
      else
        @storage[i] = 0
    return

  apply: (board) ->
    @storage = board

