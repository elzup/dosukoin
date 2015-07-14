$ ->
  ### enchant.js ###
  enchant()
  MAP_WIDTH = 1024
  MAP_HEIGHT = 512
  game = new Core(MAP_WIDTH, MAP_HEIGHT)
  game.preload "images/chara1.png"
  game.fps = 20

  game.onload = ->
    console.log "game onload"
    bear = new Sprite(32, 32)
    console.log game.assets
    bear.image = game.assets['images\/chara1.png']
    game.rootScene.addChild(bear)
    bear.frame = [6, 6, 7, 7]

    bear.tl.moveBy(288, 0, 10)
    .scaleTo(-1, 1, 10)
    .moveBy(-288, 0, 90)
    .scaleTo(1, 1, 10)
    .loop()
    console.log "game onload end"
    return

  game.start()

  ### socket.io ###
  socket = io.connect('http://localhost:3000')

  socket.emit 'new',
    room: 'user'
  # TODO: remove debug outputs
  console.log('socket connect try')

  socket.on 'init_res', (data) ->
    console.log('socket connected id' + data.id)
