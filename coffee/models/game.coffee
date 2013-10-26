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

  fallLoop: =>
    @fall()
    setTimeout(@fallLoop, @speed)

  move: (dx) ->
    pos = @player.piece.position
    unless @collide(@player.piece.storage, pos.x + dx, pos.y, @player.piece.width, @player.piece.height)
      pos.x += dx

  collide: (storage, x, y, width, height) ->
    if x < 0 or y < 0 or x + width >= @board.width or y + height >= @board.height
      true
    for dx in [0...width] by 1
      for dy in [0...height] by 1
        if storage[(dx + dy * width) * 4 + 3] > 0
          return true if @board.storage[(x + dx + (y + dy) * @board.width) * 4 + 3] > 0
    false

