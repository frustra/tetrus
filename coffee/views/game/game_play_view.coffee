class Tetrus.GamePlayView extends Batman.View
  constructor: ->
    super
    @set('fps', 0)
    @boardWidth = 10
    @boardHeight = 20
    @blockSize = 30

    @shaders = {}
    @board = new Array(@boardWidth * @boardHeight * 4)

    for x in [0...@boardWidth] by 1
      for y in [0...@boardHeight] by 1
        @board[(x + y * @boardWidth) * 4] = 0
        @board[(x + y * @boardWidth) * 4 + 1] = 0
        @board[(x + y * @boardWidth) * 4 + 2] = 200
        @board[(x + y * @boardWidth) * 4 + 3] = (if (Math.random() > 0.5) then 255 else 0)

  render: ->
    gl = @gl

    @updateBoard()

    gl.useProgram(@shaders["board"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo1)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(@shaders["players"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo2)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

    gl.useProgram(@shaders["effects"])
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.clear(gl.COLOR_BUFFER_BIT)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)
    @set('fps', @fps + 1)

  viewDidAppear: ->
    canvas = $("#glcanvas")[0]

    resizeCanvas = =>
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
      if gl
        gl.viewportWidth = canvas.width
        gl.viewportHeight = canvas.height
        @initBuffers()

    resizeCanvas()
    window.addEventListener("resize", resizeCanvas)

    try
      @gl = gl = canvas.getContext("webgl") or canvas.getContext("experimental-webgl")
      gl.viewportWidth = canvas.width
      gl.viewportHeight = canvas.height
    catch e
      console.log(e)

    console.log("Could not initialize WebGL!") unless gl

    shaderList =
      vertex:
        url: "shaders/vertex.vert"
      board:
        url: "shaders/board.frag"
      players:
        url: "shaders/players.frag"
      effects:
        url: "shaders/effects.frag"

    @loadShaders shaderList, =>
      @shaders["board"] = gl.createProgram()
      gl.attachShader(@shaders["board"], shaderList["vertex"].shader)
      gl.attachShader(@shaders["board"], shaderList["board"].shader)
      gl.linkProgram(@shaders["board"])

      @shaders["players"] = gl.createProgram()
      gl.attachShader(@shaders["players"], shaderList["vertex"].shader)
      gl.attachShader(@shaders["players"], shaderList["players"].shader)
      gl.linkProgram(@shaders["players"])

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

      @shaders["players"].vertexPositionAttribute = gl.getAttribLocation(@shaders["players"], "aVertexPosition")
      @shaders["players"].pMatrixUniform = gl.getUniformLocation(@shaders["players"], "uPMatrix")
      @shaders["players"].uBufferUniform = gl.getUniformLocation(@shaders["players"], "u_buffer")
      @shaders["players"].uSizeUniform = gl.getUniformLocation(@shaders["players"], "u_size")

      @shaders["effects"].vertexPositionAttribute = gl.getAttribLocation(@shaders["effects"], "aVertexPosition")
      @shaders["effects"].pMatrixUniform = gl.getUniformLocation(@shaders["effects"], "uPMatrix")
      @shaders["effects"].uBufferUniform = gl.getUniformLocation(@shaders["effects"], "u_buffer")
      @shaders["effects"].uSizeUniform = gl.getUniformLocation(@shaders["effects"], "u_size")

      gl.enableVertexAttribArray(@shaders["board"].vertexPositionAttribute)
      gl.enableVertexAttribArray(@shaders["players"].vertexPositionAttribute)
      gl.enableVertexAttribArray(@shaders["effects"].vertexPositionAttribute)

      @initBuffers()

      gl.clearColor(0.0, 0.0, 0.0, 0.0)
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
      gl.enable(gl.BLEND)

      do animloop = =>
        @render()
        requestAnimFrame(animloop)

  initBuffers: ->
    return unless @gl and @shaders["board"] and @shaders["players"] and @shaders["effects"]

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
    @updateBoard()

    fboTexture1 = gl.createTexture()
    gl.activeTexture(gl.TEXTURE1)
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
    gl.activeTexture(gl.TEXTURE2)
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
    gl.uniform2f(@shaders["board"].uBoardSizeUniform, @boardWidth, @boardHeight)
    gl.uniform1f(@shaders["board"].uBlockSizeUniform, @blockSize)

    gl.useProgram(@shaders["players"])
    gl.uniformMatrix4fv(@shaders["players"].pMatrixUniform, false, pMatrix)
    gl.vertexAttribPointer(@shaders["players"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(@shaders["players"].uBufferUniform, 1)
    gl.uniform2f(@shaders["players"].uSizeUniform, gl.viewportWidth, gl.viewportHeight)

    gl.useProgram(@shaders["effects"])
    gl.uniformMatrix4fv(@shaders["effects"].pMatrixUniform, false, pMatrix)
    gl.vertexAttribPointer @shaders["effects"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0
    gl.uniform1i(@shaders["effects"].uBufferUniform, 2)
    gl.uniform2f(@shaders["effects"].uSizeUniform, gl.viewportWidth, gl.viewportHeight)

  updateBoard: ->
    gl = @gl

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, @boardTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @boardWidth, @boardHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(@board))

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
