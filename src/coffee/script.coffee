socket = io.connect('http://localhost:3000')

socket.emit 'new'
# TODO: remove debug outputs
console.log('socket connect try')

socket.on 'init_res', ->
  console.log('socket connected')
