$ ->
  ### enchant.js ###
  enchant()
  MAP_WIDTH = 320
  MAP_HEIGHT = 400
  game = new Core(MAP_WIDTH, MAP_HEIGHT)
  game.preload "images/apad.png"
  game.fps = 10

  game.onload = ->
    console.log "game onload"
    controller = new Sprite(100, 100)
    console.log game.assets
    controller.image = game.assets['images/apad.png']
    # controller.scale(controller.width, controller.height)
    scale_ratio = MAP_WIDTH / controller.width
    controller.scale(scale_ratio, scale_ratio)
    controller.moveTo(MAP_WIDTH / 2 - 50, MAP_HEIGHT / 2, 50)
    game.rootScene.addChild(controller)

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

  ($ this).gShake ->
    # TODO: emit shake
