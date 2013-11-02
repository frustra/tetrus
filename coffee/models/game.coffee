class Tetrus.Game extends Batman.Object
  constructor: ->
    @keys = new Tetrus.KeyHandler(this)
    @running = false
    @keyTimer = 0

  create: ->
    @board = new Tetrus.Board
    @player = new Tetrus.Player
    @peer = new Tetrus.PeerPlayer
    @score = 0
    @speed = 750

  start: ->
    @running = true
    @fallLoop()
    @dropLoop()
    @moveLoop()

  stop: ->
    if @running
      @running = false
      @fire('game:over')

  dropLoop: =>
    return unless @running
    @fall() if @dropping
    setTimeout(@dropLoop, @speed / 15)

  moveLoop: =>
    return unless @running
    if Date.now() - @keyTimer > 75
      @player.piece.move(-1, 0, @board) if @keys.states.left
      @player.piece.move(1, 0, @board) if @keys.states.right
      @keyTimer = Date.now()
    setTimeout(@moveLoop, 15)

  fall: ->
    unless @player.piece.move(0, 1, @board)
      @dropping = false
      @placePiece(@player.piece)
      @player.setNextPiece()

  fallLoop: =>
    return unless @running
    @fall()
    setTimeout(@fallLoop, @speed)

  drop: ->
    @dropping = false
    while @player.piece.move(0, 1, @board) then
    @placePiece(@player.piece)
    @player.setNextPiece()

  lose: ->
    if @running
      Tetrus.Flash.message("Game Over")
      @stop()

  placePiece: (piece) ->
    if piece.position.y <= 0
      @lose()
      return

    @board.place(piece)
    @clearLines()

    @fire('piece:place')

  clearLines: ->
    for y in [0...@board.height] by 1
      all = @board.width
      for x in [0...@board.width] by 1
        all-- if @board.storage[(x + y * @board.width) * 4 + 3] > 0
      if all == 0
        @board.removeLine(y)
