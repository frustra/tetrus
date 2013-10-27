// Copyright 2013 Frustra Software. All rights reserved.
// Use of this source code is governed by the MIT license,
// which can be found in the LICENSE file.

package server

import (
	"encoding/json"
	"log"
	"net"
	"net/http"
	"strconv"

	"github.com/gorilla/websocket"
)

type Map map[string]interface{}

type Server struct {
	listener net.Listener
	Players  map[string]*Player
	Debug bool

	http.Server
}

type Conn struct {
	*websocket.Conn
}

type Player struct {
	conn     *Conn
	username string

	peer *Player
}

func New(port int, debug bool) (*Server, error) {
	s := &Server{
		Players: make(map[string]*Player),
		Debug: debug,
		Server: http.Server{
			Addr: ":" + strconv.Itoa(port),
		},
	}
	http.HandleFunc("/play_socket", s.ServeWS)
	http.Handle("/lobby/", http.RedirectHandler("/", 302))
	http.Handle("/play/", http.RedirectHandler("/", 302))
	http.Handle("/", http.FileServer(http.Dir("./static/")))

	return s, nil
}

func (s *Server) ListenAndServe() error {
	listener, err := net.Listen("tcp", s.Addr)
	s.listener = listener
	if err != nil {
		return err
	}

	s.Serve(s.listener)
	return nil
}

func (conn *Conn) Send(data interface{}) {
	buffer, err := json.Marshal(data)
	if err == nil {
		conn.WriteMessage(websocket.TextMessage, buffer)
	}
}

func (conn *Conn) SendError(err string) {
	conn.Send(map[string]string{"error": err})
	conn.Close()
}

func (s *Server) ServeWS(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", 405)
		return
	}

	websocketConn, err := websocket.Upgrade(w, r, nil, 1024, 1024)
	conn := &Conn{Conn: websocketConn}

	if _, ok := err.(websocket.HandshakeError); ok {
		http.Error(w, "not a websocket handshake", 400)
		return
	} else if err != nil {
		log.Println(err)
		return
	}

	r.ParseForm()
	usernames, exists := r.Form["username"]
	if !exists || len(usernames) != 1 || usernames[0] == "" {
		conn.SendError("username can't be blank")
		return
	}
	username := usernames[0]

	_, exists = s.Players[username]
	if exists {
		conn.SendError("username already in use")
		return
	}

	p := &Player{conn: conn, username: username}

	for _, player := range s.Players {
		player.conn.Send(Map{"type": "player:joined", "player": Map{"username": p.username}})
	}

	s.Players[username] = p
	conn.Send(Map{"type": "connected"})

	if s.Debug {
		log.Println("Player", username, "connected")
	}
	defer func() {
		if p.peer != nil {
			p.peer.peer = nil
			p.peer.conn.Send(Map{"type": "game:ended", "reason": "Peer Disconnected"})
		}
		delete(s.Players, username)
		for _, player := range s.Players {
			player.conn.Send(Map{"type": "player:left", "player": Map{"username": p.username}})
		}
		if s.Debug {
			log.Println("Player", username, "disconnected")
		}
	}()

	for {
		messageType, messageBytes, err := conn.ReadMessage()
		if err != nil || messageType != websocket.TextMessage {
			return
		}

		var message Map
		if err := json.Unmarshal(messageBytes, &message); err != nil {
			log.Println(err)
			return
		}
		s.HandleMessage(p, message)
	}
}

func (s *Server) HandleMessage(source *Player, message Map) error {
	var err error

	switch message["command"] {
	case "fetch":
		for _, player := range s.Players {
			if player != source {
				source.conn.Send(Map{"type": "player:joined", "player": Map{"username": player.username}})
			}
		}
	case "invite:send":
		s.RelayInviteCommand("invite:received", source, message)
	case "invite:accept":
		s.RelayInviteCommand("invite:accepted", source, message)
	case "invite:reject":
		s.RelayInviteCommand("invite:rejected", source, message)
	case "invite:cancel":
		s.RelayInviteCommand("invite:cancelled", source, message)
	case "peer:offer":
		targetName := message["username"]
		if targetName, ok := targetName.(string); ok {
			// No security.
			target := s.Players[targetName]
			if target == nil {
				source.conn.SendError("invalid peer")
				return err
			}
			if target.peer == nil && source.peer == nil {
				target.peer = source
				source.peer = target
			} else {
				source.conn.SendError("invalid game session")
				return err
			}
			target.conn.Send(Map{"type": "peer:offer", "description": message["description"]})
		} else {
			source.conn.SendError("invalid peer")
		}
	case "peer:answer":
		if source.peer == nil || source.peer.peer != source {
			source.conn.SendError("invalid game session")
			return err
		}
		source.peer.conn.Send(Map{"type": "peer:answer", "description": message["description"]})
	case "peer:handshake":
		if source.peer == nil || source.peer.peer != source {
			source.conn.SendError("invalid game session")
			return err
		}
		source.peer.conn.Send(Map{"type": "peer:handshake:complete"})
		source.conn.Send(Map{"type": "peer:handshake:complete"})
	case "peer:candidate":
		if source.peer == nil || source.peer.peer != source {
			source.conn.SendError("invalid game session")
			return err
		}
		source.peer.conn.Send(Map{"type": "peer:candidate", "candidate": message["candidate"]})
	case "game:end":
		if source.peer == nil || source.peer.peer != source {
			return err
		}
		source.peer.conn.Send(Map{"type": "game:ended"})
		source.peer.peer = nil
		source.peer = nil
	default:
		if s.Debug {
			log.Println("got a weird message", message)
		}
	}
	return err
}

func (s *Server) RelayInviteCommand(command string, source *Player, message Map) {
	targetName := message["username"]
	if targetName, ok := targetName.(string); ok {
		target := s.Players[targetName]
		target.conn.Send(Map{"type": command, "invite": Map{"username": source.username}})
	} else {
		source.conn.SendError("invalid peer")
	}
}
