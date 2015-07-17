
MAP_M = 16
MAP_WIDTH = 1024
MAP_WIDTH_M = 1024 / MAP_M
MAP_HEIGHT = 512
MAP_HEIGHT_M = 512 / MAP_M

GAME_FPS = 20
SHAKE_TIMER_SECOND = GAME_FPS * 0.5
FALL_TIMER = GAME_FPS * 2

PLAYER_IMAGE_SIZE = 32

STAGE_WATER = 3
STAGE_SPAWN = 5
BlockType =
  GRASS: 0
  WATER: 1
  SAND: 2
  BLOCK_HEAD: 3
  BLOCK: 4
  TILE: 5
Frame =
  Stand: 0
  Walk: 1
  Attack: 2
  Damage: 3
  None: -1

core = null
game = null

class Player
  @LIFE_START = 3
  @V_RATIO = 6
  @VA_RATIO = 20

  @width = 64
  @height = 64

  @State =
    Normal: 0
    Attack: 1
    Fall: 2
    Start: 3

  @MoveState =
    Stand: 0
    Walk: 1

  @R = @width / 2

  updateState: (@state) ->
    @sprite.frame = [
      Frame.Stand
      Frame.Attack
      [Frame.Damage, Frame.Damage, Frame.None, Frame.None]
      [Frame.Walk, Frame.None]
    ][@state]

  updateMoveState: ->
    if @state != Player.State.Normal
      return
    if @moveState()
      @sprite.frame = [Frame.Stand, Frame.Walk][core.frame % 8 / 4]
    else
      @sprite.frame = Frame.Stand

  constructor: (@_id, @pos) ->
    @init_pos = new Victor(0, 0).copy(@pos)
    @velocity = new Victor(0, 0)
    @accelerator = new Victor(0.8, 0.8)
    console.log(@accelerator)
    @rad = 0
    @pow = 0

    @shake_timer = 0
    @fall_timer = 0

    @sprite = new Sprite(PLAYER_IMAGE_SIZE, PLAYER_IMAGE_SIZE)
    @sprite.scale(Player.width / PLAYER_IMAGE_SIZE, Player.height / PLAYER_IMAGE_SIZE)
    # @sprite.scale(2, 2)
    @sprite.image = core.assets['/images/chara1.png']
    @sprite.moveTo(@pos.x, @pos.y)
    core.rootScene.addChild(@sprite)
    @preMoveState = 0
    @game_init()

  # 各ゲームの開始時の初期化
  game_init: ->
    @kill = 0
    @life = Player.LIFE_START
    @updateState(Player.State.Normal)

  ox: ->
    @pos.x + Player.width / 2

  oy: ->
    @pos.y + Player.height / 2

  moveState: ->
    (@velocity.length() != 0) + 0

  update_dire: (@rad, @pow) ->
    if @state in [Player.State.Fall]
      return
    # 上限指定
    mr = Player.V_RATIO * @pow / 90
    @velocity.add new Victor(0, 1).rotate(-@rad).multiply(new Victor(mr, mr))
    @sprite.rotation = 180 - @rad * 180 / Math.PI
    return

  stop: ->
    @velocity = new Victor(0, 0)
    @vy = 0
    @shake_timer = 0

  dump: ->
    console.log "#{@_id} s:#{@state} fill:#{@fall_timer} atack:#{@shake_timer}\n #{@pos}, #{@velocity}"

  onenterframe: ->
    # @dump()
    switch @state
      when Player.State.Attack
        @shake_timer -= 1
        if @shake_timer <= 0
          @updateState(Player.State.Normal)
      when Player.State.Fall
        @fall_timer -= 1
        if @fall_timer < FALL_TIMER / 2
          @updateState(Player.State.Start)
      when Player.State.Start
        @fall_timer -= 1
        if @fall_timer <= 0
          @updateState(Player.State.Normal)

    if @state != Player.State.Fall
      @move()

    @updateMoveState()
    @preMoveState = @moveState()
    return

  move: () ->
    # NOTE: 順序は？
    @pos.add(@velocity)
    @velocity.multiply(@accelerator)
    if @velocity.length() < 0.5
      @velocity = new Victor(0, 0)
    @sprite.moveTo(@pos.x, @pos.y)

  shake: ->
    if not @moveState() or @state != Player.State.Normal
      return
    @shake_timer = SHAKE_TIMER_SECOND
    # TODO: vx chceck
    @velocity.add(new Victor(0, 1).rotate(-@rad).multiply(new Victor(Player.VA_RATIO, Player.VA_RATIO)))
    # @vx += Math.sin(@rad) * Player.VA_RATIO
    # @vy += Math.cos(@rad) * Player.VA_RATIO
    @updateState(Player.State.Attack)
    return

  fall: ->
    if @state == Player.State.Fall
      return
    @stop()
    @life -= 1
    if @life == 0
      @die()
      return
    @fall_timer = FALL_TIMER
    console.log('fall!!')
    @updateState(Player.State.Fall)
    @pos.copy @init_pos
    @sprite.tl.moveTo(@pos.x, @pos.y, FALL_TIMER / 2)

  die: ->
    console.log "die(#{@_id}): "

  close: ->
    core.rootScene.removeChild(@sprite)

class Game
  constructor: ->
    @players = {}
    @setup_map()

  add_player: (id) ->
    mx = ElzupUtils.rand_range(STAGE_SPAWN, MAP_WIDTH_M - STAGE_SPAWN)
    my = ElzupUtils.rand_range(STAGE_SPAWN, MAP_HEIGHT_M - STAGE_SPAWN)
    # @baseMap[my][mx] = 6
    # @map.loadData(@baseMap)
    x = mx * MAP_M + (MAP_M - Player.width) / 2
    y = my * MAP_M + (MAP_M - Player.height) / 2
    # TODO: 衝突チェック
    @players[id] = new Player(id, new Victor(x, y))

  remove_player: (id) ->
    if id not of @players
      return false
    @players[id].close()
    delete @players[id]
    true

  onenterframe: ->
    for id, p of @players
      p.onenterframe()
      # ステージアウトチェック
      # console.log(p.ox(), p.oy())
      type = @map_type(p.ox(), p.oy())
      # console.log(type)
      if type == BlockType.WATER
        p.fall()

      # 自分より後のプレイヤーについて衝突判定
      start = false
      for id2, p2 of @players
        if start
          Game.conflict(p, p2)
          # p, p2 の衝突判定, 反発処理
        if id2 == id
          start = true

  @conflict: (p1, p2)->
    dv = Victor.fromObject(p1.pos).subtract(p2.pos)
    len = dv.length()
    d = Player.width - len
    if d < 0
      return
    if len > 0
      len = 1 / len
    # dx *= len
    # dy *= len
    console.log("bomp!")
    ratio = 0.1
    d /= 2.0

    e = 1
    # m1 = (1 + e / 2) *

    dv.multiply(new Victor(d * ratio, d * ratio))
    console.log(dv)
    console.log(p1.velocity)
    p1.velocity.add(dv)
    p2.velocity.subtract(dv)

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

    # console.log @baseMap
    @map = new Map(MAP_M, MAP_M)
    @map.image = core.assets['/images/map0.png']
    @map.loadData(@baseMap)
    core.rootScene.addChild(@map)

  map_type: (sx, sy) ->
    [mx, my] = Game.map_pos(sx, sy)
    @baseMap[my][mx]

  @map_pos: (sx, sy) ->
    mx = ElzupUtils.clamp(Math.floor(sx / MAP_M), MAP_WIDTH_M)
    my = ElzupUtils.clamp(Math.floor(sy / MAP_M), MAP_HEIGHT_M)
    [mx, my]

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
    if data.id not of game.players
      return
    game.remove_player(data.id)
    ($ ".user[user-id=#{data.id}]").remove()
    console.log "leave user: " + data.id
    console.log game.players

  socket.on 'move', (data) ->
    if data.id not of game.players
      return
    if data.pow != 0
      game.players[data.id].update_dire(data.rad, data.pow)
    console.log "move"
    console.log data

  socket.on 'shake', (data) ->
    if data.id not of game.players
      return
    game.players[data.id].shake()
    console.log "shake"
    console.log data
