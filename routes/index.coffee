express = require('express')
router = express.Router()

### GET home page. ###

router.get '/', (req, res, next) ->
  res.render 'index',
    title: 'ドスコin!'
  return

router.get '/c', (req, res, next) ->
  res.render 'controller',
    title: 'コントーラー ドスコin!'
  return

module.exports = router
