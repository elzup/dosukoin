app = require('../app')

###*
# Socket io
###

skio = (server, io) ->
  server.listen app.get('port'), ->
    console.log('listening !!')

  io.on 'connection', (socket) ->
    socket.on 'new', ->
      console.log 'new : ' + socket.id
      # 送信元のみに返す
      io.to(socket.id).emit 'init_res'

    socket.on 'disconnect', ->
      console.log 'exit : ' + socket.id
      data =
        id: socket.id
      io.emit 'removeuser', data

module.exports = skio
