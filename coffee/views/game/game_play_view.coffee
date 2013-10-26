class Tetrus.GamePlayView extends Batman.View
  constructor: ->
    super
    @set('fps', 0)
    @fpscounter = 0
    @blockSize = 25

    setInterval =>
      @set('fps', @fpscounter)
      @fpscounter = 0
    , 1000

    @shaders = {}


  render: ->
    gl = @gl

    @updateBoard()

    gl.useProgram(@shaders["board"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo1)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(@shaders["player1"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo2)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(@shaders["player2"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo1)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(@shaders["effects"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)
    @fpscounter++

  viewDidAppear: ->
    canvas = $("#glcanvas")[0]

    try
      @gl = gl = canvas.getContext("webgl") or canvas.getContext("experimental-webgl")
      gl.viewportWidth = canvas.width = @controller.board.width * @blockSize
      gl.viewportHeight = canvas.height = @controller.board.height * @blockSize
    catch e
      console.log(e)

    console.log("Could not initialize WebGL!") unless gl

    shaderList =
      vertex:
        url: "shaders/vertex.vert"
      board:
        url: "shaders/board.frag"
      player:
        url: "shaders/player.frag"
      effects:
        url: "shaders/effects.frag"

    @loadShaders shaderList, =>
      @shaders["board"] = gl.createProgram()
      gl.attachShader(@shaders["board"], shaderList["vertex"].shader)
      gl.attachShader(@shaders["board"], shaderList["board"].shader)
      gl.linkProgram(@shaders["board"])

      @shaders["player1"] = gl.createProgram()
      gl.attachShader(@shaders["player1"], shaderList["vertex"].shader)
      gl.attachShader(@shaders["player1"], shaderList["player"].shader)
      gl.linkProgram(@shaders["player1"])

      @shaders["player2"] = gl.createProgram()
      gl.attachShader(@shaders["player2"], shaderList["vertex"].shader)
      gl.attachShader(@shaders["player2"], shaderList["player"].shader)
      gl.linkProgram(@shaders["player2"])

      @shaders["effects"] = gl.createProgram()
      gl.attachShader(@shaders["effects"], shaderList["vertex"].shader)
      gl.attachShader(@shaders["effects"], shaderList["effects"].shader)
      gl.linkProgram(@shaders["effects"])

      for name of @shaders
        unless gl.getProgramParameter(@shaders[name], gl.LINK_STATUS)
          console.log("Could not initialize shader: " + name)
          return

      @shaders["board"].vertexPositionAttribute = gl.getAttribLocation(@shaders["board"], "aVertexPosition")
      @shaders["board"].pMatrixUniform = gl.getUniformLocation(@shaders["board"], "uPMatrix")
      @shaders["board"].uBoardUniform = gl.getUniformLocation(@shaders["board"], "u_board")
      @shaders["board"].uBoardSizeUniform = gl.getUniformLocation(@shaders["board"], "u_boardsize")
      @shaders["board"].uBlockSizeUniform = gl.getUniformLocation(@shaders["board"], "u_blocksize")

      @shaders["player1"].vertexPositionAttribute = gl.getAttribLocation(@shaders["player1"], "aVertexPosition")
      @shaders["player1"].pMatrixUniform = gl.getUniformLocation(@shaders["player1"], "uPMatrix")
      @shaders["player1"].uPieceUniform = gl.getUniformLocation(@shaders["player1"], "u_piece")
      @shaders["player1"].uPiecePositionUniform = gl.getUniformLocation(@shaders["player1"], "u_piecepos")
      @shaders["player1"].uPieceSizeUniform = gl.getUniformLocation(@shaders["player1"], "u_piecesize")
      @shaders["player1"].uBoardSizeUniform = gl.getUniformLocation(@shaders["player1"], "u_boardsize")
      @shaders["player1"].uBlockSizeUniform = gl.getUniformLocation(@shaders["player1"], "u_blocksize")
      @shaders["player1"].uBufferUniform = gl.getUniformLocation(@shaders["player1"], "u_buffer")
      @shaders["player1"].uSizeUniform = gl.getUniformLocation(@shaders["player1"], "u_size")

      @shaders["player2"].vertexPositionAttribute = gl.getAttribLocation(@shaders["player2"], "aVertexPosition")
      @shaders["player2"].pMatrixUniform = gl.getUniformLocation(@shaders["player2"], "uPMatrix")
      @shaders["player2"].uPieceUniform = gl.getUniformLocation(@shaders["player2"], "u_piece")
      @shaders["player2"].uPiecePositionUniform = gl.getUniformLocation(@shaders["player2"], "u_piecepos")
      @shaders["player2"].uPieceSizeUniform = gl.getUniformLocation(@shaders["player2"], "u_piecesize")
      @shaders["player2"].uBoardSizeUniform = gl.getUniformLocation(@shaders["player2"], "u_boardsize")
      @shaders["player2"].uBlockSizeUniform = gl.getUniformLocation(@shaders["player2"], "u_blocksize")
      @shaders["player2"].uBufferUniform = gl.getUniformLocation(@shaders["player2"], "u_buffer")
      @shaders["player2"].uSizeUniform = gl.getUniformLocation(@shaders["player2"], "u_size")

      @shaders["effects"].vertexPositionAttribute = gl.getAttribLocation(@shaders["effects"], "aVertexPosition")
      @shaders["effects"].pMatrixUniform = gl.getUniformLocation(@shaders["effects"], "uPMatrix")
      @shaders["effects"].uBufferUniform = gl.getUniformLocation(@shaders["effects"], "u_buffer")
      @shaders["effects"].uSizeUniform = gl.getUniformLocation(@shaders["effects"], "u_size")

      gl.enableVertexAttribArray(@shaders["board"].vertexPositionAttribute)
      gl.enableVertexAttribArray(@shaders["player1"].vertexPositionAttribute)
      gl.enableVertexAttribArray(@shaders["player2"].vertexPositionAttribute)
      gl.enableVertexAttribArray(@shaders["effects"].vertexPositionAttribute)

      @initBuffers()

      gl.clearColor(0.0, 0.0, 0.0, 0.0)
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
      gl.enable(gl.BLEND)

      do animloop = =>
        @render()
        requestAnimationFrame(animloop)

  initBuffers: ->
    return unless @gl and @shaders["board"] and @shaders["player1"] and @shaders["player2"] and @shaders["effects"]

    gl = @gl

    vertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer)
    vertices = [
      gl.viewportWidth, gl.viewportHeight
      0.0, gl.viewportHeight
      gl.viewportWidth, 0.0
      0.0, 0.0
    ]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)

    @boardTexture = gl.createTexture()
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, @boardTexture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

    @playerOneTexture = gl.createTexture()
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, @playerOneTexture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

    @playerTwoTexture = gl.createTexture()
    gl.activeTexture(gl.TEXTURE2)
    gl.bindTexture(gl.TEXTURE_2D, @playerTwoTexture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

    fboTexture1 = gl.createTexture()
    gl.activeTexture(gl.TEXTURE3)
    gl.bindTexture(gl.TEXTURE_2D, fboTexture1)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.viewportWidth, gl.viewportHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    @fbo1 = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo1)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture1, 0)

    fboTexture2 = gl.createTexture()
    gl.activeTexture(gl.TEXTURE4)
    gl.bindTexture(gl.TEXTURE_2D, fboTexture2)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.viewportWidth, gl.viewportHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    @fbo2 = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo2)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture2, 0)

    pMatrix = mat4.ortho(0, gl.viewportWidth, gl.viewportHeight, 0, 0.001, 100000)
    gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight)

    gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer)
    gl.useProgram(@shaders["board"])
    gl.uniformMatrix4fv(@shaders["board"].pMatrixUniform, false, pMatrix)
    gl.vertexAttribPointer(@shaders["board"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(@shaders["board"].uBoardUniform, 0)
    gl.uniform2f(@shaders["board"].uBoardSizeUniform, @controller.board.width, @controller.board.height)
    gl.uniform1f(@shaders["board"].uBlockSizeUniform, @blockSize)

    gl.useProgram(@shaders["player1"])
    gl.uniformMatrix4fv(@shaders["player1"].pMatrixUniform, false, pMatrix)
    gl.vertexAttribPointer(@shaders["player1"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(@shaders["player1"].uPieceUniform, 1)
    gl.uniform2f(@shaders["player1"].uBoardSizeUniform, @controller.board.width, @controller.board.height)
    gl.uniform1f(@shaders["player1"].uBlockSizeUniform, @blockSize)
    gl.uniform1i(@shaders["player1"].uBufferUniform, 3)
    gl.uniform2f(@shaders["player1"].uSizeUniform, gl.viewportWidth, gl.viewportHeight)

    gl.useProgram(@shaders["player2"])
    gl.uniformMatrix4fv(@shaders["player2"].pMatrixUniform, false, pMatrix)
    gl.vertexAttribPointer(@shaders["player2"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(@shaders["player2"].uPieceUniform, 2)
    gl.uniform2f(@shaders["player2"].uBoardSizeUniform, @controller.board.width, @controller.board.height)
    gl.uniform1f(@shaders["player2"].uBlockSizeUniform, @blockSize)
    gl.uniform1i(@shaders["player2"].uBufferUniform, 4)
    gl.uniform2f(@shaders["player2"].uSizeUniform, gl.viewportWidth, gl.viewportHeight)

    gl.useProgram(@shaders["effects"])
    gl.uniformMatrix4fv(@shaders["effects"].pMatrixUniform, false, pMatrix)
    gl.vertexAttribPointer @shaders["effects"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0
    gl.uniform1i(@shaders["effects"].uBufferUniform, 3)
    gl.uniform2f(@shaders["effects"].uSizeUniform, gl.viewportWidth, gl.viewportHeight)

    @updateBoard()

  updateBoard: ->
    gl = @gl

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, @boardTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @controller.board.width, @controller.board.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@controller.board.storage))

    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, @playerOneTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @controller.player.piece.width, @controller.player.piece.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@controller.player.piece.storage))

    gl.activeTexture(gl.TEXTURE2)
    gl.bindTexture(gl.TEXTURE_2D, @playerTwoTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @controller.peer.piece.width, @controller.peer.piece.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@controller.peer.piece.storage))

    gl.useProgram(@shaders["player1"])
    gl.uniform2f(@shaders["player1"].uPiecePositionUniform, @controller.player.piece.position.x, @controller.player.piece.position.y)
    gl.uniform2f(@shaders["player1"].uPieceSizeUniform, @controller.player.piece.width, @controller.player.piece.height)

    gl.useProgram(@shaders["player2"])
    gl.uniform2f(@shaders["player2"].uPiecePositionUniform, @controller.peer.piece.position.x, @controller.peer.piece.position.y)
    gl.uniform2f(@shaders["player2"].uPieceSizeUniform, @controller.peer.piece.width, @controller.peer.piece.height)

  loadShaders: (shaderList, callback) ->
    gl = @gl

    completeCallback = (name, source) ->
      ext = shaderList[name].url.substr(shaderList[name].url.length - 5)
      if ext is ".frag"
        shaderList[name].shader = gl.createShader(gl.FRAGMENT_SHADER)
      else if ext is ".vert"
        shaderList[name].shader = gl.createShader(gl.VERTEX_SHADER)
      else
        shaderList[name].shader = false
        return

      gl.shaderSource(shaderList[name].shader, source)
      gl.compileShader(shaderList[name].shader)

      unless gl.getShaderParameter(shaderList[name].shader, gl.COMPILE_STATUS)
        console.log("Error in shader: " + name)
        console.log(gl.getShaderInfoLog(shaderList[name].shader))
        shaderList[name].shader = false
        return

      complete = true
      for name of shaderList
        unless shaderList[name].shader
          complete = false
          break

      callback() if complete

    for name of shaderList
      do (name) ->
        options =
          url: shaderList[name].url
          success: (data) ->
            completeCallback(name, data)
        new Batman.Request(options).send()
