_    = require 'lodash'
http = require 'http'

class EnforceMessageRateLimit
  constructor: (options={}) ->
    {@cache, @Date, @msgRateLimit} = options
    @Date ?= Date
    @msgRateLimit ?= 20*60 # messages per minute

  _doCallback: (request, code, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
    callback null, response

  do: (request, callback) =>
    uuid = request?.metadata?.auth?.as
    uuid ?= request?.metadata?.auth?.uuid
    minuteKey = @getMinuteKey()
    @cache.hget minuteKey, uuid, (error, msgRate) =>
      return @_doCallback request, 500, callback if error?
      msgRate = parseInt msgRate
      return @_doCallback request, 429, callback if msgRate >= @msgRateLimit
      return @_doCallback request, 204, callback

  getMinuteKey: ()=>
    time = @Date.now()
    @startMinute = Math.floor(time / (1000*60))
    return "message-rate:minute-#{@startMinute}"

module.exports = EnforceMessageRateLimit
