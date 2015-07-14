MAP_WIDTH = 1024
MAP_HEIGHT = 512

core = null
game = null

class Player
  @LIFE_START = 3

  constructor: (@id, @x, @y) ->
    @vx = 0
    @vy = 0
    @dire = 0

    @sprite = new Sprite(32, 32)
    @sprite.image = core.assets['images\/chara1.png']
    @sprite.moveTo(@x, @y)
    core.rootScene.addChild(@sprite)

    @game_init()

  game_init: ->
    @kill = 0
    @life = Player.LIFE_START

class Game
  constructor: ->
    @players = {}

  add_player: (id) ->
    # TODO: 100 -> random value
    @players[id] = new Player(id, 100, 100)

  remove_player: (id) ->
    if id not in @players
      return false
    delete @players[id]
    true

$ ->
  ### enchant.js ###
  enchant()
  core = new Core(MAP_WIDTH, MAP_HEIGHT)
  core.preload "images/chara1.png"
  core.fps = 20

  game = new Game

  core.onload = ->
    console.log "core onload end"
    return

  core.start()



  ### socket.io ###
  socket = io.connect('http://localhost:3000')

  socket.emit 'new',
    room: 'top'
  console.log('socket connect try')

  socket.on 'init_res', (data) ->
    console.log('socket connected id' + data.id)

  socket.on 'join', (data) ->
    game.add_player(data.id)
    console.log "join user: " + data.id
    console.log game.players

  socket.on 'leave', (data) ->
    if not game.remove_player(data.id)
      return
    console.log "leave user: " + data.id
    console.log members

  socket.on 'move', (data) ->
    console.log "move"
    console.log data

