MAP_WIDTH = 1024
MAP_HEIGHT = 512

core = null
game = null

class Player
  @LIFE_START = 3
  @V_RATIO = 3

  constructor: (@_id, @x, @y) ->
    @vx = 0
    @vy = 0
    @rad = 0
    @pow = 0

    @sprite = new Sprite(32, 32)
    @sprite.image = core.assets['images\/chara1.png']
    @sprite.moveTo(@x, @y)
    core.rootScene.addChild(@sprite)

    @game_init()

  # 各ゲームの開始時の初期化
  game_init: ->
    @kill = 0
    @life = Player.LIFE_START

  update_dire: (@rad, @pow) ->
    if @pow == 0
      @vx = 0
      @vy = 0
      return
    @vx = Math.sin(@rad) * Player.V_RATIO
    @vy = Math.cos(@rad) * Player.V_RATIO
    return

  onenterframe: ->
    @move(@x + @vx, @y + @vy)

  move: (@x, @y) ->
    @sprite.moveTo(@x, @y)



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

  onenterframe: ->
    for id, p of @players
      p.onenterframe()


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

  core.onenterframe = ->
    game.onenterframe()

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
    game.players[data.id].update_dire(data.rad, data.pow)
    console.log "move"
    console.log data

