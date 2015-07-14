app = require('../app')

###*
# Socket io
###

skio = (server, io) ->
  server.listen app.get('port'), ->
    console.log('listening !!')

  io.on 'connection', (socket) ->

    # TODO: data.room => socket.nsp.name
    socket.on 'new', (data) ->
      console.log 'new : ' + socket.id + " [" + data.room + "]"
      # 送信元のみに返す
      socket.join(data.room)
      if data.room == 'user'
        io.to('top').emit  'join',
          id: socket.id
      io.to(socket.id).emit 'init_res',
        id: socket.id

    socket.on 'move', (data) ->
      data.id = socket.id
      io.to('top').emit 'move', data

    socket.on 'disconnect', ->
      console.log 'exit : ' + socket.id + " [" + socket.nsp.name + "]"
      # NOTE: room から自動で socket.id は削除されるのか？
      # NOTE: ユーザの切断のみ emit する？
      # if ROOM == '/c'
      io.to('top').emit 'leave',
        id: socket.id

module.exports = skio
