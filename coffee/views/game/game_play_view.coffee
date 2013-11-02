shaderList =
  vertex:
    url: "/static/shaders/vertex.vert"
  board:
    url: "/static/shaders/board.frag"
  player1:
    url: "/static/shaders/player.frag"
  player2:
    url: "/static/shaders/player.frag"
  effects:
    url: "/static/shaders/effects.frag"

uniformList = [
  "uPMatrix"
  "u_board"
  "u_boardsize"
  "u_blocksize"
  "u_piece"
  "u_piecepos"
  "u_piecesize"
  "u_buffer"
  "u_size"
  "u_xoffset"
]

class Tetrus.GamePlayView extends Batman.View
  constructor: ->
    super
    @set('fps', 0)
    @fpscounter = 0
    @blockSize = 25

    @shadersNextPiece = {}

  fpsTimer: ->
    return unless @controller.game.running
    @set('fps', @fpscounter)
    @fpscounter = 0
    setTimeout @fpsTimer, 1000

  renderBoard: (gl) ->
    @updateBoard(gl)

    gl.useProgram(gl.shaders["board"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo1)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(gl.shaders["player2"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo2)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(gl.shaders["player1"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo1)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(gl.shaders["effects"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

  renderPiece: (gl) ->
    @updatePiece(gl)

    gl.useProgram(gl.shaders["player1"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

  viewDidAppear: ->
    # this is getting called twice for some reason
    return if @_attachedHandler
    @_attachedHandler = true

    @loadShaders shaderList, (shaderList) =>
      @controller.game.once 'game:ready', =>
        Batman.developer.log("Initializing renderer")

        boardCanvas = $("#boardcanvas")[0]
        boardCanvas.width = @controller.game.board.width * @blockSize
        boardCanvas.height = @controller.game.board.height * @blockSize

        pieceCanvas = $("#piececanvas")[0]
        pieceCanvas.width = 6 * @blockSize
        pieceCanvas.height = 4 * @blockSize

        @boardGL = @startRendering(boardCanvas, shaderList)
        @pieceGL = @startRendering(pieceCanvas, shaderList)

        @initBoardBuffers(@boardGL)
        @initPieceBuffers(@pieceGL)

        @fpsTimer()
        do animloop = =>
          if !@isDead and @controller
            @renderBoard(@boardGL)
            @renderPiece(@pieceGL)
            @fpscounter++
            requestAnimationFrame(animloop)

  startRendering: (canvas, shaderList) ->
    try
      gl = canvas.getContext("webgl") or canvas.getContext("experimental-webgl")
      gl.viewportWidth = canvas.width
      gl.viewportHeight = canvas.height
    catch e
      console.log(e)

    unless gl
      console.log("Could not initialize WebGL!")
      return null

    shaderList = jQuery.extend(true, {}, shaderList)
    @compileShaders(gl, shaderList)

    gl.shaders = {}
    for name of shaderList
      continue if name is "vertex"
      gl.shaders[name] = gl.createProgram()
      gl.attachShader(gl.shaders[name], shaderList["vertex"].shader)
      gl.attachShader(gl.shaders[name], shaderList[name].shader)
      gl.linkProgram(gl.shaders[name])

      unless gl.shaders[name] && gl.getProgramParameter(gl.shaders[name], gl.LINK_STATUS)
        console.log("Could not initialize shader: " + name)
        return null

      gl.shaders[name].vertexPositionAttribute = gl.getAttribLocation(gl.shaders[name], "aVertexPosition")
      gl.enableVertexAttribArray(gl.shaders[name].vertexPositionAttribute)

      gl.shaders[name].uniform = {}
      for uniform in uniformList
        utmp = gl.getUniformLocation(gl.shaders[name], uniform)
        gl.shaders[name].uniform[uniform] = utmp if utmp

    gl.clearColor(0.0, 0.0, 0.0, 0.0)
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.enable(gl.BLEND)

    return gl

  initPieceBuffers: (gl) ->
    vertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer)
    vertices = [
      gl.viewportWidth, gl.viewportHeight
      0.0, gl.viewportHeight
      gl.viewportWidth, 0.0
      0.0, 0.0
    ]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)

    pMatrix = mat4.ortho(0, gl.viewportWidth, gl.viewportHeight, 0, 0.001, 100000)
    gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight)

    @pieceTexture = @createTexture(gl, gl.TEXTURE0)
    gl.useProgram(gl.shaders["player1"])
    gl.uniformMatrix4fv(gl.shaders["player1"].uniform["uPMatrix"], false, pMatrix)
    gl.vertexAttribPointer(gl.shaders["player1"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(gl.shaders["player1"].uniform["u_piece"], 0)
    gl.uniform2f(gl.shaders["player1"].uniform["u_boardsize"], 6, 4)
    gl.uniform1f(gl.shaders["player1"].uniform["u_blocksize"], @blockSize)
    gl.uniform2f(gl.shaders["player1"].uniform["u_size"], 0, 0)

    @updatePiece(gl)

  initBoardBuffers: (gl) ->
    vertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer)
    vertices = [
      gl.viewportWidth, gl.viewportHeight
      0.0, gl.viewportHeight
      gl.viewportWidth, 0.0
      0.0, 0.0
    ]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)

    pMatrix = mat4.ortho(0, gl.viewportWidth, gl.viewportHeight, 0, 0.001, 100000)
    gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight)

    @boardTexture = @createTexture(gl, gl.TEXTURE0)
    @playerOneTexture = @createTexture(gl, gl.TEXTURE1)
    @playerTwoTexture = @createTexture(gl, gl.TEXTURE2)

    fboTexture1 = @createTexture(gl, gl.TEXTURE3)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.viewportWidth, gl.viewportHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    @fbo1 = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo1)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture1, 0)

    fboTexture2 = @createTexture(gl, gl.TEXTURE4)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.viewportWidth, gl.viewportHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    @fbo2 = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo2)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture2, 0)

    gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer)
    gl.useProgram(gl.shaders["board"])
    gl.uniformMatrix4fv(gl.shaders["board"].uniform["uPMatrix"], false, pMatrix)
    gl.vertexAttribPointer(gl.shaders["board"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(gl.shaders["board"].uniform["u_board"], 0)
    gl.uniform2f(gl.shaders["board"].uniform["u_boardsize"], @controller.game.board.width, @controller.game.board.height)
    gl.uniform1f(gl.shaders["board"].uniform["u_blocksize"], @blockSize)

    gl.useProgram(gl.shaders["player1"])
    gl.uniformMatrix4fv(gl.shaders["player1"].uniform["uPMatrix"], false, pMatrix)
    gl.vertexAttribPointer(gl.shaders["player1"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(gl.shaders["player1"].uniform["u_piece"], 1)
    gl.uniform2f(gl.shaders["player1"].uniform["u_boardsize"], @controller.game.board.width, @controller.game.board.height)
    gl.uniform1f(gl.shaders["player1"].uniform["u_blocksize"], @blockSize)
    gl.uniform1i(gl.shaders["player1"].uniform["u_buffer"], 4)
    gl.uniform2f(gl.shaders["player1"].uniform["u_size"], gl.viewportWidth, gl.viewportHeight)

    gl.useProgram(gl.shaders["player2"])
    gl.uniformMatrix4fv(gl.shaders["player2"].uniform["uPMatrix"], false, pMatrix)
    gl.vertexAttribPointer(gl.shaders["player2"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(gl.shaders["player2"].uniform["u_piece"], 2)
    gl.uniform2f(gl.shaders["player2"].uniform["u_boardsize"], @controller.game.board.width, @controller.game.board.height)
    gl.uniform1f(gl.shaders["player2"].uniform["u_blocksize"], @blockSize)
    gl.uniform1i(gl.shaders["player2"].uniform["u_buffer"], 3)
    gl.uniform2f(gl.shaders["player2"].uniform["u_size"], gl.viewportWidth, gl.viewportHeight)

    gl.useProgram(gl.shaders["effects"])
    gl.uniformMatrix4fv(gl.shaders["effects"].uniform["uPMatrix"], false, pMatrix)
    gl.vertexAttribPointer gl.shaders["effects"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0
    gl.uniform1i(gl.shaders["effects"].uniform["u_buffer"], 3)
    gl.uniform2f(gl.shaders["effects"].uniform["u_size"], gl.viewportWidth, gl.viewportHeight)

    @updateBoard(gl)

  updateBoard: (gl) ->
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, @boardTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @controller.game.board.width, @controller.game.board.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@controller.game.board.storage))

    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, @playerOneTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @controller.game.player.piece.width, @controller.game.player.piece.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@controller.game.player.piece.storage))

    gl.activeTexture(gl.TEXTURE2)
    gl.bindTexture(gl.TEXTURE_2D, @playerTwoTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @controller.game.peer.piece.width, @controller.game.peer.piece.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@controller.game.peer.piece.storage))

    gl.useProgram(gl.shaders["player1"])
    gl.uniform2f(gl.shaders["player1"].uniform["u_piecepos"], @controller.game.player.piece.position.x, @controller.game.player.piece.position.y)
    gl.uniform2f(gl.shaders["player1"].uniform["u_piecesize"], @controller.game.player.piece.width, @controller.game.player.piece.height)

    gl.useProgram(gl.shaders["player2"])
    gl.uniform2f(gl.shaders["player2"].uniform["u_piecepos"], @controller.game.peer.piece.position.x, @controller.game.peer.piece.position.y)
    gl.uniform2f(gl.shaders["player2"].uniform["u_piecesize"], @controller.game.peer.piece.width, @controller.game.peer.piece.height)

  updatePiece: (gl) ->
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, @pieceTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @controller.game.player.nextPiece.width, @controller.game.player.nextPiece.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@controller.game.player.nextPiece.storage))

    gl.useProgram(gl.shaders["player1"])
    gl.uniform1f(gl.shaders["player1"].uniform["u_xoffset"], 2 - @controller.game.player.nextPiece.width / 2)
    gl.uniform2f(gl.shaders["player1"].uniform["u_piecepos"], 1, 1)
    gl.uniform2f(gl.shaders["player1"].uniform["u_piecesize"], @controller.game.player.nextPiece.width, @controller.game.player.nextPiece.height)

  loadShaders: (shaderList, callback) ->
    for name of shaderList
      do (name) ->
        new Batman.Request
          url: shaderList[name].url + "?" + Date.now()
          success: (data) ->
            shaderList[name].source = data
            complete = true
            for name of shaderList
              unless shaderList[name].source
                complete = false
                break
            callback(shaderList) if complete

  createTexture: (gl, id) ->
    texture = gl.createTexture()
    gl.activeTexture(id)
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    return texture

  compileShaders: (gl, shaderList) ->
    for name of shaderList
      ext = shaderList[name].url.substr(shaderList[name].url.length - 5)
      if ext is ".frag"
        shaderList[name].shader = gl.createShader(gl.FRAGMENT_SHADER)
      else if ext is ".vert"
        shaderList[name].shader = gl.createShader(gl.VERTEX_SHADER)
      else
        shaderList[name].shader = false
        continue

      gl.shaderSource(shaderList[name].shader, shaderList[name].source)
      gl.compileShader(shaderList[name].shader)

      unless gl.getShaderParameter(shaderList[name].shader, gl.COMPILE_STATUS)
        console.log("Error in shader: " + name)
        console.log(gl.getShaderInfoLog(shaderList[name].shader))
        shaderList[name].shader = false
        continue
    return
