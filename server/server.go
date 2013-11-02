// Copyright 2013 Frustra Software. All rights reserved.
// Use of this source code is governed by the MIT license,
// which can be found in the LICENSE file.

package server

import (
	"encoding/json"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"

	"github.com/gorilla/websocket"
)

type Map map[string]interface{}

type Server struct {
	listener net.Listener
	Players  map[string]*Player

	Root         string
	Debug        bool
	LayoutBuffer []byte

	http.Server
}

type Conn struct {
	*websocket.Conn
}

type Browser struct {
	Name string `json:"name"`
	Major int `json:"major"`
}

type Player struct {
	conn     *Conn
	Username string `json:"username"`
	Browser  *Browser `json:"browser"`

	peer *Player
}

func New(port int, debug bool) (*Server, error) {
	s := &Server{
		Players: make(map[string]*Player),
		Debug:   debug,
		Server: http.Server{
			Addr: ":" + strconv.Itoa(port),
		},
	}

	var err error
	s.Root, err = os.Getwd()
	if err != nil {
		panic(err)
	}
	log.Println("Executing from directory:", s.Root)
	s.LoadManifest()

	http.HandleFunc("/play_socket", s.ServeWS)
	http.Handle("/lobby/", http.RedirectHandler("/", 302))
	http.Handle("/play/", http.RedirectHandler("/", 302))
	http.Handle("/html/", http.FileServer(http.Dir(".")))
	http.Handle("/static/", http.FileServer(http.Dir(".")))
	http.HandleFunc("/", s.ServeLayout)

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

type Session struct {
	Type string `json:"type"`
	Host string `json:"host"`
}

func GetSession(a, b *Browser) *Session {
	s := &Session{}
	if a.Name == "firefox" {
		switch b.Name {
		case "firefox":
			s.Type = "sctp"
			s.Host = "any"
		case "chrome":
			if b.Major > 30 {
				s.Type = "sctp"
				s.Host = "yes"
			} else {
				return nil
			}
		default:
			return nil
		}
	} else if a.Name == "chrome" {
		switch b.Name {
		case "firefox":
			if a.Major > 30 {
				s.Type = "sctp"
				s.Host = "no"
			} else {
				return nil
			}
		case "chrome":
			if a.Major > 30 && b.Major > 30 {
				s.Type = "sctp"
				s.Host = "any"
			} else if a.Major <= 30 && b.Major <= 30 {
				s.Type = "rtp"
				s.Host = "any"
			} else {
				return nil
			}
		default:
			return nil
		}
	}
	return s
}

func (s *Server) ParseBrowser(conn *Conn, r *http.Request) *Browser {
	browsers, browserExists := r.Form["browser"]
	versions, versionExists := r.Form["version"]
	if !browserExists || !versionExists || len(browsers) != 1 || len(versions) != 1 {
		return nil
	}

	browser := browsers[0]
	version, _ := strconv.Atoi(versions[0])
	b := &Browser{browser, version}

	if browser == "chrome" {
		if version >= 25 {
			return b
		}
		conn.SendError("Chrome support starts at version 25")
	} else if browser == "firefox" {
		if version >= 22 {
			return b
		}
		conn.SendError("Firefox support starts at version 22")
	} else {
		conn.SendError("browser does not support webrtc")
	}
	return nil
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

	browser := s.ParseBrowser(conn, r)
	if browser == nil {
		return
	}

	_, exists = s.Players[username]
	if exists {
		conn.SendError("username already in use")
		return
	}

	p := &Player{conn: conn, Username: username, Browser: browser}

	for _, player := range s.Players {
		player.conn.Send(Map{"type": "player:joined", "player": p})
	}

	s.Players[username] = p
	conn.Send(Map{"type": "connected"})

	if s.Debug {
		log.Println("Player", username, "connected using", browser)
	}
	defer func() {
		if p.peer != nil {
			p.peer.peer = nil
			p.peer.conn.Send(Map{"type": "game:ended", "reason": "Peer Disconnected"})
		}
		delete(s.Players, username)
		for _, player := range s.Players {
			player.conn.Send(Map{"type": "player:left", "player": p})
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
	case "ping":
		source.conn.Send(Map{"type": "pong"})
	case "fetch":
		for _, player := range s.Players {
			if player != source {
				source.conn.Send(Map{"type": "player:joined", "player": player})
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
		if target != nil {
			session := GetSession(source.Browser, target.Browser)
			if session != nil {
				target.conn.Send(Map{"type": command, "invite": Map{"username": source.Username}, "session": session})
			} else {
				source.conn.Send(Map{"type": "invite:invalid", "peer_browser": target.Browser})
			}
		} else {
			source.conn.SendError("invalid peer")
		}
	} else {
		source.conn.SendError("invalid peer")
	}
}
