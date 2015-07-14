express = require('express')
router = express.Router()

### GET home page. ###

router.get '/', (req, res, next) ->
  res.render 'index',
    title: 'ドスコin!'
    js_filename: 'script'
  return

router.get '/c', (req, res, next) ->
  res.render 'index',
    title: 'コントーラー ドスコin!'
    js_filename: 'controller'
  return

module.exports = router
