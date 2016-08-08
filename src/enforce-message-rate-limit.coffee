_                = require 'lodash'
http             = require 'http'
RateLimitChecker = require 'meshblu-core-rate-limit-checker'

class EnforceMessageRateLimit
  constructor: (options={}) ->
    {@cache, @Date, @msgRateLimit} = options
    @Date ?= Date
    @rateLimitChecker = new RateLimitChecker {client: @cache, @Date, @msgRateLimit}

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
    @rateLimitChecker.isLimited {uuid}, (error, result) =>
      return @_doCallback request, 500, callback if error?
      if result
        code = 429
      else
        code = 204
      return @_doCallback request, code, callback

module.exports = EnforceMessageRateLimit
