
MAP_M = 16
MAP_WIDTH = 1024
MAP_WIDTH_M = 1024 / MAP_M
MAP_HEIGHT = 512
MAP_HEIGHT_M = 512 / MAP_M

GAME_FPS = 20
SHAKE_TIMER_SECOND = GAME_FPS * 0.5
FALL_TIMER = GAME_FPS * 2

STAGE_WATER = 3
BlockType =
  GRASS: 0
  WATER: 1
  SAND: 2
  BLOCK_HEAD: 3
  BLOCK: 4
  TILE: 5
Frame =
  Stand: 0
  Walk1: 1
  Walk2: 2
  Damage: 3
  None: -1

core = null
game = null

class Player
  @LIFE_START = 3
  @V_RATIO = 6
  @VA_RATIO = 2

  @width = 32
  @height = 32

  @State =
    Normal: 0
    Attack: 1
    Fall: 2
    Start: 3

  @MoveState =
    Stand: 0
    Walk: 1


  constructor: (@_id, @x, @y) ->
    @init_x = @x
    @init_y = @y
    @vx = 0
    @vy = 0
    @rad = 0
    @pow = 0

    @shake_timer = 0
    @fall_timer = 0
    @state = Player.State.Normal
    @preState = @state
    @preMoveState = Player.MoveState.Stand

    @sprite = new Sprite(Player.width, Player.height)
    @sprite.image = core.assets['/images/chara1.png']
    @sprite.moveTo(@x, @y)
    core.rootScene.addChild(@sprite)
    @game_init()

  # 各ゲームの開始時の初期化
  game_init: ->
    @kill = 0
    @life = Player.LIFE_START
    @state = Player.State.Normal

  ox: ->
    @x + Player.width / 2

  oy: ->
    @y + Player.height / 2

  moveState: ->
    ((@vx | @vy) == 0) + 0

  update_dire: (@rad, @pow) ->
    if @state in [Player.State.Attack, Player.State.Fall]
      return
    @vx = Math.sin(@rad) * Player.V_RATIO
    @vy = Math.cos(@rad) * Player.V_RATIO
    return

  stop: ->
    @vx = 0
    @vy = 0
    @shake_timer = 0

  dump: ->
    console.log "#{@_id} s:#{@state} fill:#{@fall_timer} atack:#{@shake_timer}\n #{@x}, #{@y}, #{@vx}, #{@vy}"

  onenterframe: ->
    va = 1
    @dump()
    switch @state
      when Player.State.Attack
        @shake_timer -= 1
        va = Player.VA_RATIO
        if @shake_timer <= 0
          @state = Player.State.Normal
          @stop()
      when Player.State.Fall
        @fall_timer -= 1
        if @fall_timer < FALL_TIMER / 2
          @state = Player.State.Start
          @stop()
      when Player.State.Start
        @fall_timer -= 1
        if @fall_timer <= 0
          @state = Player.State.Normal

    if @state != Player.State.Fall
      @move(@x + @vx * va, @y + @vy * va)


    # state が変わった時に frame を換える
    if (@moveState() != @preMoveState) and (@state is Player.State.Normal)
      # @sprite.frame = [Frame.Stand, [Frame.Walk1, Frame.Walk1, Frame.Walk2, Frame.Walk2]][@moveState()]
      if @moveState() == 0
        # @sprite.frame = Frame.Walk2
        @sprite.frame = Frame.Walk1
      else
        @sprite.frame = Frame.Stand
    if @state is not @preState
      @sprite.frame = [
        Frame.Stand
        Frame.Walk1
        Frame.Damage
        Frame.Walk1
      ][@state]

    @preState = @state
    @preMoveState = @moveState()

  move: (@x, @y) ->
    @sprite.moveTo(@x, @y)

  shake: ->
    if @moveState() or @state != Player.State.Normal
      return
    @shake_timer = SHAKE_TIMER_SECOND
    @state = Player.State.Attack
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
    @state = Player.State.Fall
    @x = @init_x
    @y = @init_y
    @sprite.tl.moveTo(@init_x, @init_y, FALL_TIMER / 2)

  die: ->
    console.log "die(#{@_id}): "

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
      # ステージアウトチェック
      # console.log(p.ox(), p.oy())
      type = @map_type(p.ox(), p.oy())
      # console.log(type)
      if type == BlockType.WATER
        p.fall()


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
    if not data.id of game.players
      return
    game.remove_player(data.id)
    ($ ".user[user-id=#{data.id}]").remove()
    console.log "leave user: " + data.id
    console.log game.players

  socket.on 'move', (data) ->
    if not data.id of game.players
      return
    if data.pow != 0
      game.players[data.id].update_dire(data.rad, data.pow)
    else
      game.players[data.id].stop()
    console.log "move"
    console.log data

  socket.on 'shake', (data) ->
    if not data.id of game.players
      return
    game.players[data.id].shake()
    console.log "shake"
    console.log data
