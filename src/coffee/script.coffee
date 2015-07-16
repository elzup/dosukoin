
MAP_M = 16
MAP_WIDTH = 1024
MAP_WIDTH_M = 1024 / MAP_M
MAP_HEIGHT = 512
MAP_HEIGHT_M = 512 / MAP_M

GAME_FPS = 20
SHAKE_TIMER_SECOND = GAME_FPS * 0.5

STAGE_WATER = 3
BlockType =
  GRASS: 0
  WATER: 1
  SAND: 2
  BLOCK_HEAD: 3
  BLOCK: 4
  TILE: 5

core = null
game = null

class Player
  @LIFE_START = 3
  @V_RATIO = 6
  @VA_RATIO = 2

  constructor: (@_id, @x, @y) ->
    @vx = 0
    @vy = 0
    @rad = 0
    @pow = 0

    @shake_timer = 0

    @sprite = new Sprite(32, 32)
    @sprite.image = core.assets['/images/chara1.png']
    @sprite.moveTo(@x, @y)
    core.rootScene.addChild(@sprite)

    @game_init()

  # 各ゲームの開始時の初期化
  game_init: ->
    @kill = 0
    @life = Player.LIFE_START

  update_dire: (@rad, @pow) ->
    if @shake_timer > 0
      return
    if @pow == 0
      @stop()
      return
    @vx = Math.sin(@rad) * Player.V_RATIO
    @vy = Math.cos(@rad) * Player.V_RATIO
    return

  stop: ->
    @vx = 0
    @vy = 0

  onenterframe: ->
    va = 1
    if @shake_timer > 0
      @shake_timer -= 1
      va = Player.VA_RATIO
      if @shake_timer == 0
        @sprite.frame = 0
        @stop()
    @move(@x + @vx * va, @y + @vy * va)

  move: (@x, @y) ->
    @sprite.moveTo(@x, @y)

  shake: ->
    if (@vx | @vy) == 0 | @shake_timer > 0
      return
    @shake_timer = SHAKE_TIMER_SECOND
    @sprite.frame = 3
    return

  close: ->
    console.log("remove sprite")
    core.rootScene.removeChild(@sprite)


class Game
  constructor: ->
    @players = {}
    @setup_map()

  add_player: (id) ->
    # TODO: 100 -> random value
    @players[id] = new Player(id, 100, 100)

  remove_player: (id) ->
    if id not of @players
      return false
    @players[id].close()
    delete @players[id]
    true

  onenterframe: ->
    for id, p of @players
      p.onenterframe()

  setup_map: ->
    @baseMap = [0...MAP_HEIGHT_M]

    # 縁付ステージの生成
    for j in @baseMap
      @baseMap[j] = [0...MAP_WIDTH_M]
      for i in @baseMap[j]
        @baseMap[j][i] = BlockType.GRASS
        if j < STAGE_WATER or MAP_HEIGHT_M - STAGE_WATER <= j or i < STAGE_WATER or MAP_WIDTH_M - STAGE_WATER <= i
          @baseMap[j][i] = BlockType.WATER
        else if j == STAGE_WATER or j == MAP_HEIGHT_M - STAGE_WATER - 1 or i == STAGE_WATER or i == MAP_WIDTH_M - STAGE_WATER - 1
          @baseMap[j][i] = BlockType.TILE

    console.log @baseMap
    @map = new Map(MAP_M, MAP_M)
    @map.image = core.assets['/images/map0.png']
    @map.loadData(@baseMap)
    core.rootScene.addChild(@map)


$ ->
  ### enchant.js ###
  enchant()
  core = new Core(MAP_WIDTH, MAP_HEIGHT)
  core.preload ['/images/chara1.png', '/images/map0.png']
  core.fps = GAME_FPS

  core.onload = ->
    game = new Game
    console.log "core onload end"
    return

  core.onenterframe = ->
    if game
      game.onenterframe()

  core.start()


  ### socket.io ###
  socket = io.connect()

  socket.emit 'new',
    room: 'top'
  console.log('socket connect try')

  socket.on 'init_res', (data) ->
    console.log('socket connected id' + data.id)

  socket.on 'join', (data) ->
    game.add_player(data.id)
    # pageのユーザリストにも追加
    ($ '#users-box').append(($ '<dir/>',
      class: "user"
      "user-id": data.id
    ).append(data.id))
    console.log "join user: " + data.id
    console.log game.player

  socket.on 'leave', (data) ->
    if not data.id of game.players
      return
    game.remove_player(data.id)
    ($ ".user[user-id=#{data.id}]").remove()
    console.log "leave user: " + data.id
    console.log game.players

  socket.on 'move', (data) ->
    if not data.id of game.players
      return
    game.players[data.id].update_dire(data.rad, data.pow)
    console.log "move"
    console.log data

  socket.on 'shake', (data) ->
    if not data.id of game.players
      return
    game.players[data.id].shake()
    console.log "shake"
    console.log data
