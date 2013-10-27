// Generated by CoffeeScript 1.6.3
(function() {
  var _ref, _ref1, _ref2, _ref3, _ref4,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Batman.extend(Batman.config, {
    pathToApp: '/',
    pathToHTML: '/html'
  });

  Batman.View.prototype.cache = false;

  window.Tetrus = (function(_super) {
    __extends(Tetrus, _super);

    function Tetrus() {
      _ref = Tetrus.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Tetrus.layout = 'layout';

    Tetrus.root('landing#index');

    Tetrus.route('lobby', 'lobby#index');

    Tetrus.route('play', 'game#play');

    Tetrus.route('404', 'errors#404');

    Tetrus.on('error', function(event) {
      event.preventDefault();
      console.error(event);
      return Tetrus.Flash.error("Unexpected Error");
    });

    Tetrus.redirectWindow = function(location) {
      return window.location = location;
    };

    Tetrus.flash = function(message) {
      return console.err(message);
    };

    Tetrus.reset = function() {
      if (this.conn) {
        this.conn.close();
        delete this.conn;
      }
      this.set('username', '');
      this.set('peerHash', new Batman.Hash);
      this.off('socket:error');
      this.off('socket:connected');
      return this.off('socket:message');
    };

    Tetrus.setup = function(ready) {
      var _this = this;
      this.conn = new WebSocket("ws://" + (this.get('hostAddr')) + "/play_socket?username=" + (encodeURIComponent(this.get('username'))));
      return Batman.mixin(this.conn, {
        sendJSON: function(obj) {
          return this.send(JSON.stringify(obj));
        },
        onmessage: function(event) {
          var message;
          message = JSON.parse(event.data);
          if (message.error) {
            _this.fire('socket:error', message.error);
            return _this.reset();
          } else if (message.type === 'connected') {
            return _this.fire('socket:connected');
          } else {
            return _this.fire('socket:message', message);
          }
        },
        onopen: function() {
          return _this.fire('socket:opened');
        },
        onclose: function(event) {
          return _this.fire('socket:error', 'Lost Connection');
        },
        onerror: function(event) {
          return _this.fire('socket:error', 'Unexpected Error');
        }
      });
    };

    Tetrus.play = function(invite) {
      this.set('peer', {
        username: invite.get('username'),
        isServer: !invite.get('isSource')
      });
      return Batman.redirect('/play');
    };

    Tetrus.attachGlobalErrorHandler = function() {
      var _this = this;
      return this.on('socket:error', function(err) {
        return Tetrus.Flash.error(err);
      });
    };

    return Tetrus;

  })(Batman.App);

  $(function() {
    Tetrus.set('hostAddr', window.location.host);
    Tetrus.reset();
    return Tetrus.run();
  });

  Tetrus.APIStorage = (function(_super) {
    __extends(APIStorage, _super);

    APIStorage.prototype._addJsonExtension = function(url) {
      if (url.indexOf('?') !== -1 || url.substr(-5, 5) === '.json') {
        return url;
      }
      return url + '.json';
    };

    APIStorage.prototype.urlForRecord = function() {
      return this._addJsonExtension(APIStorage.__super__.urlForRecord.apply(this, arguments));
    };

    APIStorage.prototype.urlForCollection = function() {
      return this._addJsonExtension(APIStorage.__super__.urlForCollection.apply(this, arguments));
    };

    function APIStorage() {
      APIStorage.__super__.constructor.apply(this, arguments);
      this.defaultRequestOptions = {
        type: 'json'
      };
    }

    return APIStorage;

  })(Batman.RestStorage);

  Tetrus.Flash = Batman({
    _message: "",
    _class: "message",
    _flash: function(message) {
      var bottom, node;
      this.set('_message', message);
      node = $('#flash');
      bottom = node.css('bottom');
      return node.animate({
        bottom: 0
      }, 200).delay(5000).animate({
        bottom: bottom
      }, 800);
    },
    message: function(message) {
      this.set('_class', 'message');
      return this._flash(message);
    },
    error: function(error) {
      this.set('_class', 'error');
      return this._flash(error);
    }
  });

  Tetrus.Board = (function() {
    function Board() {
      this.storage = new Array(10 * 20 * 4);
    }

    Board.get = function(x, y) {
      var offset;
      offset = (x + y * 10) * 4;
      return {
        r: this.storage[offset],
        g: this.storage[offset + 1],
        b: this.storage[offset + 2],
        a: this.storage[offset + 3]
      };
    };

    Board.set = function(x, y, color) {
      var offset;
      offset = (x + y * 10) * 4;
      this.storage[offset] = color.r;
      this.storage[offset + 1] = color.g;
      this.storage[offset + 2] = color.b;
      return this.storage[offset + 3] = color.a;
    };

    Board.removeLine = function(y) {
      var endIndex, i, _i;
      endIndex = (y + 1) * 40 - 4;
      for (i = _i = endIndex; _i >= 0; i = _i += -1) {
        if (i >= 40) {
          this.storage[i] = this.storage[i - 40];
        } else {
          this.storage[i] = 0;
        }
      }
    };

    return Board;

  })();

  Tetrus.Game = (function() {
    function Game() {
      this.board = new Tetrus.Board;
      this.piece = new Tetrus.Piece;
      this.peerPiece = new Tetrus.Piece;
    }

    return Game;

  })();

  Tetrus.Invite = (function(_super) {
    var x, _fn, _i, _len, _ref2,
      _this = this;

    __extends(Invite, _super);

    function Invite() {
      _ref1 = Invite.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Invite.prototype._sendCommand = function(command) {
      return Tetrus.conn.sendJSON({
        command: "invite:" + command,
        username: this.get('username')
      });
    };

    _ref2 = ['accept', 'reject', 'send'];
    _fn = function(x) {
      return Invite.prototype[x] = function() {
        return this._sendCommand(x);
      };
    };
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      x = _ref2[_i];
      _fn(x);
    }

    return Invite;

  }).call(this, Batman.Model);

  Tetrus.Peer = (function(_super) {
    __extends(Peer, _super);

    function Peer() {
      Peer.__super__.constructor.apply(this, arguments);
    }

    return Peer;

  })(Batman.Model);

  Tetrus.Piece = (function() {
    function Piece() {
      this.position = {
        x: 0,
        y: 0
      };
      this.storage = [];
    }

    Piece.prototype.rotate = function(direction) {};

    return Piece;

  })();

  Tetrus.GameController = (function(_super) {
    __extends(GameController, _super);

    function GameController() {
      _ref2 = GameController.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    GameController.prototype.routingKey = 'game';

    GameController.prototype.play = function() {
      this.peer = new Tetrus.Peer(Tetrus.get('peer'));
      this.set('isServer', this.peer.get('isServer'));
      return this._negotiate();
    };

    GameController.prototype.start = function() {
      this.pollForTimeout();
      this.game = new Tetrus.Game;
      return this.send({
        type: 'ping'
      });
    };

    GameController.prototype.disconnect = function() {
      this.set('connecting', false);
      this.set('connected', false);
      delete this.peerChannel;
      delete this.peerConnection;
      Tetrus.conn.sendJSON({
        command: 'game:end'
      });
      return Batman.redirect('/lobby');
    };

    GameController.prototype._onMessage = function(event) {
      var line, message, _i, _len, _ref3, _results;
      this.lastResponse = new Date().getTime();
      message = JSON.parse(event.data);
      console.log(message);
      switch (message.type) {
        case "ping":
          return this.send({
            type: 'pong',
            timeStamp: event.timeStamp
          });
        case "pong":
          return this.set('rtt', event.timeStamp - message.timeStamp);
        case "board":
          return this.game.board.apply(message.board);
        case "piece":
          return this.game.peerPiece.apply(message.piece);
        case "score":
          this.game.fallSpeed += message.deltaSpeed;
          this.game.score += message.deltaScore;
          _ref3 = message.lines;
          _results = [];
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            line = _ref3[_i];
            _results.push(this.game.board.removeLine(line));
          }
          return _results;
          break;
        default:
          console.error(message);
          Tetrus.Flash.error("Communication Error");
          return this.disconnect();
      }
    };

    GameController.prototype.send = function(message) {
      return this.peerChannel.send(JSON.stringify(message));
    };

    GameController.prototype.pollForTimeout = function() {
      var check, lastCheck,
        _this = this;
      lastCheck = 0;
      this.lastResponse = new Date().getTime();
      check = function() {
        if (!_this.connected) {
          return;
        }
        if (_this.lastResponse < lastCheck) {
          Tetrus.Flash.error("Connection timed out");
          return _this.disconnect();
        } else {
          lastCheck = new Date().getTime();
          return setTimeout(check, 2000);
        }
      };
      return check();
    };

    GameController.prototype._bindPeerChannel = function(channel) {
      var _this = this;
      this.peerChannel = channel;
      channel.onmessage = function(event) {
        return _this._onMessage(event);
      };
      channel.onopen = function() {
        Batman.developer.log("peer channel opened");
        _this.set('connecting', false);
        _this.set('connected', true);
        return _this.start();
      };
      channel.onclose = function() {
        Batman.developer.log("peer channel closed");
        return _this.disconnect();
      };
      return channel.onerror = function(error) {
        Batman.developer.log("peer channel errored:", error);
        return _this.disconnect();
      };
    };

    GameController.prototype._negotiate = function() {
      var candidates,
        _this = this;
      this.set('connecting', true);
      this.set('connected', false);
      this.peerConnection = new RTCPeerConnection({
        iceServers: [
          {
            url: 'stun:stun.l.google.com:19302'
          }
        ]
      }, {
        optional: [
          {
            RtpDataChannels: true
          }
        ]
      });
      candidates = [];
      this.peerConnection.onicecandidate = function(event) {
        var candidate;
        if (candidate = event.candidate) {
          Batman.developer.log("local candidate", candidate.candidate);
          return candidates.push(candidate);
        }
      };
      this.peerConnection.ondatachannel = function(event) {
        return _this._bindPeerChannel(event.channel);
      };
      if (this.isServer) {
        this._bindPeerChannel(this.peerConnection.createDataChannel('RTCDataChannel'));
        this.peerConnection.createOffer(function(description) {
          _this.peerConnection.setLocalDescription(description);
          Batman.developer.log("local sdp", description.sdp);
          return Tetrus.conn.sendJSON({
            command: 'peer:offer',
            description: description,
            username: _this.peer.get('username')
          });
        }, null, null);
      }
      return Tetrus.on('socket:message', function(message) {
        var candidate, setRemoteDescription, _i, _len;
        setRemoteDescription = function() {
          var description;
          description = new RTCSessionDescription(message.description);
          _this.peerConnection.setRemoteDescription(description);
          return Batman.developer.log("remote sdp", description.sdp);
        };
        switch (message.type) {
          case "peer:offer":
            setRemoteDescription();
            return _this.peerConnection.createAnswer(function(description) {
              _this.peerConnection.setLocalDescription(description);
              Batman.developer.log("local sdp", description.sdp);
              return Tetrus.conn.sendJSON({
                command: 'peer:answer',
                description: description
              });
            }, null, null);
          case "peer:answer":
            setRemoteDescription();
            return Tetrus.conn.sendJSON({
              command: 'peer:handshake'
            });
          case "peer:handshake:complete":
            candidates.push = function(candidate) {
              return Tetrus.conn.sendJSON({
                command: 'peer:candidate',
                candidate: candidate
              });
            };
            for (_i = 0, _len = candidates.length; _i < _len; _i++) {
              candidate = candidates[_i];
              candidates.push(candidate);
            }
            return candidates.length = 0;
          case "peer:candidate":
            candidate = new RTCIceCandidate(message.candidate);
            _this.peerConnection.addIceCandidate(candidate);
            return Batman.developer.log("remote candidate", candidate.candidate);
          case "game:ended":
            return _this.disconnect();
        }
      });
    };

    return GameController;

  })(Batman.Controller);

  Tetrus.LandingController = (function(_super) {
    __extends(LandingController, _super);

    function LandingController() {
      _ref3 = LandingController.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    LandingController.prototype.routingKey = 'landing';

    LandingController.prototype.index = function() {
      Tetrus.reset();
      if (window.WebSocket == null) {
        this.set('fatal', 'your browser does not support websockets');
      }
      if (!window.webrtcCompatible) {
        return this.set('fatal', 'your browser does not support webrtc');
      }
    };

    LandingController.prototype["continue"] = function() {
      var _this = this;
      Tetrus.on('socket:error', this._socketErrorHandler = function(err) {
        $('#username-error').stop(true).css({
          opacity: 0
        }).animate({
          opacity: 1
        }, 200).delay(2500).animate({
          opacity: 0
        }, 800);
        return _this.set('error', err);
      });
      Tetrus.on('socket:connected', this._socketConnectedHandler = function() {
        Tetrus.off('socket:error', _this._socketErrorHandler);
        Tetrus.off('socket:connected', _this._socketConnectedHandler);
        Tetrus.attachGlobalErrorHandler();
        return Batman.redirect('/lobby');
      });
      return Tetrus.setup();
    };

    return LandingController;

  })(Batman.Controller);

  Tetrus.LobbyController = (function(_super) {
    __extends(LobbyController, _super);

    function LobbyController() {
      _ref4 = LobbyController.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    LobbyController.prototype.routingKey = 'lobby';

    LobbyController.prototype.index = function() {
      this.set('receivedInvites', new Batman.Hash);
      if (!Tetrus.get('username')) {
        Tetrus.redirectWindow('/');
      } else {
        Tetrus.conn.sendJSON({
          command: 'fetch'
        });
      }
      return this._attachSocketListeners();
    };

    LobbyController.prototype._onMessage = function(message) {
      var invite;
      switch (message.type) {
        case "player:joined":
          return Tetrus.get('peerHash').set(message.player.username, message.player);
        case "player:left":
          this.get('receivedInvites').unset(message.player.username);
          return Tetrus.get('peerHash').unset(message.player.username);
        case "invite:accepted":
          this.unset('pending');
          return Tetrus.play(this.unset('sentInvite'));
        case "invite:rejected":
          Tetrus.Flash.message("" + (this.sentInvite.get('username')) + " rejected your invitation");
          this.unset('pending');
          return this.unset('sentInvite');
        case "invite:received":
          this.get('receivedInvites').set(message.invite.username, invite = new Tetrus.Invite(message.invite));
          return Tetrus.Flash.message("Got invitation from " + message.invite.username);
        case "invite:cancelled":
          this.get('receivedInvites').unset(message.invite.username);
          return Tetrus.Flash.message("" + message.invite.username + " cancelled their invitation");
      }
    };

    LobbyController.prototype._attachSocketListeners = function() {
      return Tetrus.on('socket:message', this._boundOnMessage = this._onMessage.bind(this));
    };

    LobbyController.accessor('peers', function() {
      return Tetrus.get('peerHash').map(function(_, value) {
        return value;
      });
    });

    LobbyController.prototype.sendInvite = function(node, event, view) {
      if (this.get('pending')) {
        return Tetrus.Flash.message('You still have a pending invitation');
      } else {
        this.set('sentInvite', new Tetrus.Invite({
          username: view.get('peer').username,
          isSource: true
        })).send();
        return this.set('pending', true);
      }
    };

    LobbyController.prototype.acceptInvite = function(node, event, view) {
      var invite;
      invite = view.get('invite');
      this.get('receivedInvites').unset(invite.get('username'));
      this.get('receivedInvites').forEach(function(invite) {
        return invite.reject();
      });
      invite.accept();
      return Tetrus.play(invite);
    };

    LobbyController.prototype.rejectInvite = function(node, event, view) {
      var invite;
      invite = view.get('invite');
      this.get('receivedInvites').unset(invite.get('username'));
      return invite.reject();
    };

    return LobbyController;

  })(Batman.Controller);

  Tetrus.GamePlayView = (function(_super) {
    __extends(GamePlayView, _super);

    function GamePlayView() {
      var x, y, _i, _j, _ref5, _ref6;
      GamePlayView.__super__.constructor.apply(this, arguments);
      this.set('fps', 0);
      this.boardWidth = 10;
      this.boardHeight = 20;
      this.blockSize = 25;
      this.shaders = {};
      this.board = new Array(this.boardWidth * this.boardHeight * 4);
      for (x = _i = 0, _ref5 = this.boardWidth; _i < _ref5; x = _i += 1) {
        for (y = _j = 0, _ref6 = this.boardHeight; _j < _ref6; y = _j += 1) {
          this.board[(x + y * this.boardWidth) * 4] = 0;
          this.board[(x + y * this.boardWidth) * 4 + 1] = 0;
          this.board[(x + y * this.boardWidth) * 4 + 2] = 200;
          this.board[(x + y * this.boardWidth) * 4 + 3] = (Math.random() > 0.5 ? 255 : 0);
        }
      }
    }

    GamePlayView.prototype.render = function() {
      var gl;
      gl = this.gl;
      this.updateBoard();
      gl.useProgram(this.shaders["board"]);
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo1);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      gl.useProgram(this.shaders["players"]);
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo2);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      gl.useProgram(this.shaders["effects"]);
      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      return this.set('fps', this.fps + 1);
    };

    GamePlayView.prototype.viewDidAppear = function() {
      var canvas, e, gl, shaderList,
        _this = this;
      canvas = $("#glcanvas")[0];
      try {
        this.gl = gl = canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
        gl.viewportWidth = canvas.width = this.boardWidth * this.blockSize;
        gl.viewportHeight = canvas.height = this.boardHeight * this.blockSize;
      } catch (_error) {
        e = _error;
        console.log(e);
      }
      if (!gl) {
        console.log("Could not initialize WebGL!");
      }
      shaderList = {
        vertex: {
          url: "shaders/vertex.vert"
        },
        board: {
          url: "shaders/board.frag"
        },
        players: {
          url: "shaders/players.frag"
        },
        effects: {
          url: "shaders/effects.frag"
        }
      };
      return this.loadShaders(shaderList, function() {
        var animloop, name;
        _this.shaders["board"] = gl.createProgram();
        gl.attachShader(_this.shaders["board"], shaderList["vertex"].shader);
        gl.attachShader(_this.shaders["board"], shaderList["board"].shader);
        gl.linkProgram(_this.shaders["board"]);
        _this.shaders["players"] = gl.createProgram();
        gl.attachShader(_this.shaders["players"], shaderList["vertex"].shader);
        gl.attachShader(_this.shaders["players"], shaderList["players"].shader);
        gl.linkProgram(_this.shaders["players"]);
        _this.shaders["effects"] = gl.createProgram();
        gl.attachShader(_this.shaders["effects"], shaderList["vertex"].shader);
        gl.attachShader(_this.shaders["effects"], shaderList["effects"].shader);
        gl.linkProgram(_this.shaders["effects"]);
        for (name in _this.shaders) {
          if (!gl.getProgramParameter(_this.shaders[name], gl.LINK_STATUS)) {
            console.log("Could not initialize shader: " + name);
            return;
          }
        }
        _this.shaders["board"].vertexPositionAttribute = gl.getAttribLocation(_this.shaders["board"], "aVertexPosition");
        _this.shaders["board"].pMatrixUniform = gl.getUniformLocation(_this.shaders["board"], "uPMatrix");
        _this.shaders["board"].uBoardUniform = gl.getUniformLocation(_this.shaders["board"], "u_board");
        _this.shaders["board"].uBoardSizeUniform = gl.getUniformLocation(_this.shaders["board"], "u_boardsize");
        _this.shaders["board"].uBlockSizeUniform = gl.getUniformLocation(_this.shaders["board"], "u_blocksize");
        _this.shaders["players"].vertexPositionAttribute = gl.getAttribLocation(_this.shaders["players"], "aVertexPosition");
        _this.shaders["players"].pMatrixUniform = gl.getUniformLocation(_this.shaders["players"], "uPMatrix");
        _this.shaders["players"].uBufferUniform = gl.getUniformLocation(_this.shaders["players"], "u_buffer");
        _this.shaders["players"].uSizeUniform = gl.getUniformLocation(_this.shaders["players"], "u_size");
        _this.shaders["effects"].vertexPositionAttribute = gl.getAttribLocation(_this.shaders["effects"], "aVertexPosition");
        _this.shaders["effects"].pMatrixUniform = gl.getUniformLocation(_this.shaders["effects"], "uPMatrix");
        _this.shaders["effects"].uBufferUniform = gl.getUniformLocation(_this.shaders["effects"], "u_buffer");
        _this.shaders["effects"].uSizeUniform = gl.getUniformLocation(_this.shaders["effects"], "u_size");
        gl.enableVertexAttribArray(_this.shaders["board"].vertexPositionAttribute);
        gl.enableVertexAttribArray(_this.shaders["players"].vertexPositionAttribute);
        gl.enableVertexAttribArray(_this.shaders["effects"].vertexPositionAttribute);
        _this.initBuffers();
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
        gl.enable(gl.BLEND);
        return (animloop = function() {
          _this.render();
          return requestAnimationFrame(animloop);
        })();
      });
    };

    GamePlayView.prototype.initBuffers = function() {
      var fboTexture1, fboTexture2, gl, pMatrix, vertexPositionBuffer, vertices;
      if (!(this.gl && this.shaders["board"] && this.shaders["players"] && this.shaders["effects"])) {
        return;
      }
      gl = this.gl;
      vertexPositionBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer);
      vertices = [gl.viewportWidth, gl.viewportHeight, 0.0, gl.viewportHeight, gl.viewportWidth, 0.0, 0.0, 0.0];
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
      this.boardTexture = gl.createTexture();
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.boardTexture);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      this.updateBoard();
      fboTexture1 = gl.createTexture();
      gl.activeTexture(gl.TEXTURE1);
      gl.bindTexture(gl.TEXTURE_2D, fboTexture1);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.viewportWidth, gl.viewportHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      this.fbo1 = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo1);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture1, 0);
      fboTexture2 = gl.createTexture();
      gl.activeTexture(gl.TEXTURE2);
      gl.bindTexture(gl.TEXTURE_2D, fboTexture2);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.viewportWidth, gl.viewportHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      this.fbo2 = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo2);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture2, 0);
      pMatrix = mat4.ortho(0, gl.viewportWidth, gl.viewportHeight, 0, 0.001, 100000);
      gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight);
      gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer);
      gl.useProgram(this.shaders["board"]);
      gl.uniformMatrix4fv(this.shaders["board"].pMatrixUniform, false, pMatrix);
      gl.vertexAttribPointer(this.shaders["board"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0);
      gl.uniform1i(this.shaders["board"].uBoardUniform, 0);
      gl.uniform2f(this.shaders["board"].uBoardSizeUniform, this.boardWidth, this.boardHeight);
      gl.uniform1f(this.shaders["board"].uBlockSizeUniform, this.blockSize);
      gl.useProgram(this.shaders["players"]);
      gl.uniformMatrix4fv(this.shaders["players"].pMatrixUniform, false, pMatrix);
      gl.vertexAttribPointer(this.shaders["players"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0);
      gl.uniform1i(this.shaders["players"].uBufferUniform, 1);
      gl.uniform2f(this.shaders["players"].uSizeUniform, gl.viewportWidth, gl.viewportHeight);
      gl.useProgram(this.shaders["effects"]);
      gl.uniformMatrix4fv(this.shaders["effects"].pMatrixUniform, false, pMatrix);
      gl.vertexAttribPointer(this.shaders["effects"].vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0);
      gl.uniform1i(this.shaders["effects"].uBufferUniform, 2);
      return gl.uniform2f(this.shaders["effects"].uSizeUniform, gl.viewportWidth, gl.viewportHeight);
    };

    GamePlayView.prototype.updateBoard = function() {
      var gl;
      gl = this.gl;
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.boardTexture);
      return gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.boardWidth, this.boardHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(this.board));
    };

    GamePlayView.prototype.loadShaders = function(shaderList, callback) {
      var completeCallback, gl, name, _results;
      gl = this.gl;
      completeCallback = function(name, source) {
        var complete, ext;
        ext = shaderList[name].url.substr(shaderList[name].url.length - 5);
        if (ext === ".frag") {
          shaderList[name].shader = gl.createShader(gl.FRAGMENT_SHADER);
        } else if (ext === ".vert") {
          shaderList[name].shader = gl.createShader(gl.VERTEX_SHADER);
        } else {
          shaderList[name].shader = false;
          return;
        }
        gl.shaderSource(shaderList[name].shader, source);
        gl.compileShader(shaderList[name].shader);
        if (!gl.getShaderParameter(shaderList[name].shader, gl.COMPILE_STATUS)) {
          console.log("Error in shader: " + name);
          console.log(gl.getShaderInfoLog(shaderList[name].shader));
          shaderList[name].shader = false;
          return;
        }
        complete = true;
        for (name in shaderList) {
          if (!shaderList[name].shader) {
            complete = false;
            break;
          }
        }
        if (complete) {
          return callback();
        }
      };
      _results = [];
      for (name in shaderList) {
        _results.push((function(name) {
          var options;
          options = {
            url: shaderList[name].url,
            success: function(data) {
              return completeCallback(name, data);
            }
          };
          return new Batman.Request(options).send();
        })(name));
      }
      return _results;
    };

    return GamePlayView;

  })(Batman.View);

  Tetrus.LayoutView = (function(_super) {
    __extends(LayoutView, _super);

    function LayoutView() {
      var _this = this;
      LayoutView.__super__.constructor.apply(this, arguments);
      Tetrus.observe('currentRoute', function(route) {
        _this.set('routingSection', route.get('controller'));
        return _this.set('routingPage', route.get('action'));
      });
    }

    LayoutView.accessor('title', function() {
      var section;
      section = this.get('routingSection');
      return "" + section + " ~ tetrus";
    });

    LayoutView.accessor('path', function() {
      var section;
      return section = this.get('routingSection');
    });

    return LayoutView;

  })(Batman.View);

}).call(this);
