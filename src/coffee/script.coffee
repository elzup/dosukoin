
MAP_M = 16
MAP_WIDTH = 720
MAP_WIDTH_M = MAP_WIDTH / MAP_M
MAP_HEIGHT = 720
MAP_HEIGHT_M = MAP_HEIGHT / MAP_M

FRAME_WIDTH = 200
GAME_WIDTH = MAP_HEIGHT + FRAME_WIDTH
GAME_HEIGHT = MAP_HEIGHT

CLOCK_WIDTH = FRAME_WIDTH
CLOCK_HEIGHT = FRAME_WIDTH

SEASON =
  SPRING: 0
  SUMMER: 1
  AUTUMN: 2
  WINTER: 3

SEASON_TABLE = [
  [SEASON.AUTUMN, SEASON.WINTER]
  [SEASON.WINTER, SEASON.SPRING]
  [SEASON.SPRING, SEASON.SUMMER]
  [SEASON.SUMMER, SEASON.AUTUMN]
]

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
  Super: 4
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

  @M = 0.01

  @R = @width / 2

  updateState: (@state) ->
    if not @isFall() and @is_super
      @sprite.frame = [Frame.Super + @fs, Frame.Super + @fs, Frame.Attack + @fs, Frame.Attack + @fs]
      return
    @sprite.frame = [
      Frame.Stand + @fs
      Frame.Attack + @fs
      [Frame.Damage + @fs, Frame.Damage + @fs, Frame.None, Frame.None]
      [Frame.Walk + @fs, Frame.None]
    ][@state]

  updateMoveState: ->
    if @state != Player.State.Normal
      return
    if @is_super
      @sprite.frame = [Frame.Super + @fs, Frame.Attack + @fs][ElzupUtils.period(core.frame, 4)]
      return
    if @moveState()
      @sprite.frame = [Frame.Stand + @fs, Frame.Walk + @fs][ElzupUtils.period(core.frame, 8)]
    else
      @sprite.frame = Frame.Stand + @fs

  constructor: (@_id, @pos) ->
    @init_pos = new Victor(0, 0).copy(@pos)
    @velocity = new Victor(0, 0)
    @accelerator = new Victor(0.8, 0.8)
    # @accelerator = new Victor(0.99, 0.99)
    console.log(@accelerator)
    @rad = 0
    @pow = 0

    @shake_timer = 0
    @fall_timer = 0
    # TODO: adapt user type
    # @type = SEASON.SPRING
    @type = ElzupUtils.rand_range(0, 4)
    console.log "type: " + @type
    @fs = @type * 5
    @is_super = false

    @m = Player.M

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

  isFall: ->
    @state is Player.State.Fall

  set_super: (@is_super) ->
    if @is_super
      @m = Player.M * 3
    else
      @m = Player.M

  update_dire: (@rad, @pow) ->
    if @isFall()
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

    if not @isFall()
      @move()

    @updateMoveState()
    @preMoveState = @moveState()
    return

  move: ->
    # NOTE: 順序は？
    @pos.add(@velocity)
    @pos.limit(MAP_WIDTH, 1.0)
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
    if @isFall()
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
  @generation_delay = GAME_FPS * 5

  constructor: ->
    @players = {}
    @setup_map()
    @setup_clock()
    @generation = 0

  add_player: (id) ->
    mx = ElzupUtils.rand_range(STAGE_SPAWN, MAP_WIDTH_M - STAGE_SPAWN)
    my = ElzupUtils.rand_range(STAGE_SPAWN, MAP_HEIGHT_M - STAGE_SPAWN)
    # @baseMap[my][mx] = 6
    # @map.loadData(@baseMap)
    x = mx * MAP_M + (MAP_M - Player.width) / 2
    y = my * MAP_M + (MAP_M - Player.height) / 2
    # TODO: 出現時衝突チェック
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
      if p.isFall()
        continue
      start = false
      for id2, p2 of @players
        if start and not p2.isFall()
          Game.conflict(p, p2)
          # p, p2 の衝突判定, 反発処理
        if id2 == id
          start = true
    # DEBUGGER: display global frame
    # console.log core.frame
    if core.frame % Game.generation_delay == 0
      @step_generation()

  step_generation: ->
    @generation = (@generation + 1) % 4
    @clock.tl.rotateBy(90, Game.generation_delay)
    for id, p of @players
      p.set_super(p.type in SEASON_TABLE[@generation])
    # NOTE: debug
    console.log("step season :" + @season())

  season: ->
    @generation % 4

  @conflict: (p0, p1)->
    # console.log p0, p1
    abVec = Victor.fromObject(p0.pos).subtract(p1.pos)
    len = abVec.length()
    # console.log "len", len
    d = Player.width - len
    if d <= 0
      return

    abVec.normalize()
    distance = Player.width - len
    syncVec = new Victor(0, 0).copy(abVec).multiply(new Victor(distance / 2, distance / 2))
    p0.pos.add(syncVec)
    p1.pos.subtract(syncVec)
    # TODO: create reflection
    e = 1.0

    m1 = new Victor(0, 0).copy(p1.velocity).subtract(p0.velocity).dot(abVec) * p1.m * (e + 1) / (p0.m + p1.m)
    m2 = new Victor(0, 0).copy(p0.velocity).subtract(p1.velocity).dot(abVec) * p0.m * (e + 1) / (p0.m + p1.m)
    p0.velocity.add(new Victor(0, 0).copy(abVec).multiply(new Victor(m1, m1)))
    p1.velocity.add(new Victor(0, 0).copy(abVec).multiply(new Victor(m2, m2)))

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

  setup_clock: ->
    @clock = new Sprite(CLOCK_WIDTH, CLOCK_HEIGHT)
    @clock.image = core.assets['/images/clock.png']
    @clock.moveTo(MAP_WIDTH, - CLOCK_HEIGHT / 2)
    # 春が半分出てる状態から始める
    @clock.rotate(135)
    # @clock.rotation = 135 * 2 * Math.PI / 360

    console.log(@clock)
    core.rootScene.addChild(@clock)

  map_type: (sx, sy) ->
    [mx, my] = Game.map_pos(sx, sy)
    # TODO: 何故か読み込めない
    if not @baseMap[my]
      return BlockType.WATER
    @baseMap[my][mx]

  @map_pos: (sx, sy) ->
    mx = ElzupUtils.clamp(Math.floor(sx / MAP_M), MAP_WIDTH_M)
    my = ElzupUtils.clamp(Math.floor(sy / MAP_M), MAP_HEIGHT_M)
    # console.log(sx, sy, " -> ", mx, my)
    [mx, my]

$ ->
  ### enchant.js ###
  enchant()
  core = new Core(GAME_WIDTH, GAME_HEIGHT)
  core.preload ['/images/chara1.png', '/images/map0.png', '/images/clock.png']
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
