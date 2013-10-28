class Tetrus.KeyHandler
  constructor: (@game) ->
    @states = left: false, right: false, down: false, space: false, z: false, x: false

  keyEvent: (keyCode, pressed) ->
    switch keyCode
      when 37 # left
        if !@states.left and pressed
          @game.player.piece.move(-1, 0, @game.board)
          @game.keyTimer = Date.now() + 75
        @states.left = pressed

      when 39 # right
        if !@states.right and pressed
          @game.player.piece.move(1, 0, @game.board)
          @game.keyTimer = Date.now() + 75
        @states.right = pressed

      when 40 # down
        if pressed
          @game.dropping = true if !@states.down
        else
          @game.dropping = false
        @states.down = pressed

      when 32 # space
        @game.drop() if !@states.space and pressed
        @states.space = pressed

      when 88 # x
        @game.player.piece.rotate(1, @game.board) if !@states.x and pressed
        @states.x = pressed

      when 90 # z
        @game.player.piece.rotate(3, @game.board) if !@states.z and pressed
        @states.z = pressed

      when 38 # up
      else return true
    return false
