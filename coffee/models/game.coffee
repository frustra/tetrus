class Tetrus.Game
  constructor: ->
    @board = new Tetrus.Board
    @player = new Tetrus.Player
    @peer = new Tetrus.Player(true)
    @score = 0
    @speed = 750

  loop: =>
    ctrl = Tetrus.get('controllers.game')
    piece = @player.piece
    ctrl.send(type: 'piece', piece: { storage: piece.storage, position: piece.position, width: piece.width, height: piece.height })

    setTimeout(@loop, 50)

  fall: ->
    pos = @player.piece.position
    unless @collide(@player.piece.storage, pos.x, pos.y + 1, @player.piece.width, @player.piece.height)
      pos.y++
    else
      @placePiece(@player.piece)
      @player.setNextPiece()

  fallLoop: =>
    @fall()
    setTimeout(@fallLoop, @speed)

  move: (dx) ->
    pos = @player.piece.position
    unless @collide(@player.piece.storage, pos.x + dx, pos.y, @player.piece.width, @player.piece.height)
      pos.x += dx

  placePiece: (piece) ->
    if piece.position.y < 0
      Tetrus.Flash.message("Game Over")
      Tetrus.get('controllers.game').disconnect()
    for x in [0...piece.width] by 1
      for y in [0...piece.height] by 1
        if piece.storage[(x + y * piece.width) * 4 + 3] > 0
          @board.storage[(piece.position.x + x + (piece.position.y + y) * @board.width) * 4] = piece.storage[(x + y * piece.width) * 4]
          @board.storage[(piece.position.x + x + (piece.position.y + y) * @board.width) * 4 + 1] = piece.storage[(x + y * piece.width) * 4 + 1]
          @board.storage[(piece.position.x + x + (piece.position.y + y) * @board.width) * 4 + 2] = piece.storage[(x + y * piece.width) * 4 + 2]
          @board.storage[(piece.position.x + x + (piece.position.y + y) * @board.width) * 4 + 3] = 255

  collide: (storage, x, y, width, height) ->
    if x < 0 or y < 0 or x + (width - 1) >= @board.width or y + (height - 1) >= @board.height
      return true
    for dx in [0...width] by 1
      for dy in [0...height] by 1
        if storage[(dx + dy * width) * 4 + 3] > 0
          return true if @board.storage[(x + dx + (y + dy) * @board.width) * 4 + 3] > 0
    false

