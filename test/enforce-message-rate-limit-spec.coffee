_ = require 'lodash'
redis = require 'fakeredis'
uuid  = require 'uuid'
EnforceMessageRateLimit = require '../'
MeshbluCoreCache = require 'meshblu-core-cache'

describe 'EnforceMessageRateLimit', ->
  before ->
    @clientKey = uuid.v1()
    @client = redis.createClient @clientKey
    cache = new MeshbluCoreCache client: redis.createClient @clientKey
    startTime = Date.now()
    FakeDate = now: -> return startTime
    @sut = new EnforceMessageRateLimit {cache: cache, Date: FakeDate}
    @request =
      metadata:
        responseId: 'its-electric'
        auth:
          uuid: 'electric-eels'
        messageType: 'received'
        options: {}
      rawData: '{}'

  describe '->do', ->
    context 'when given a valid message', ->
      before (done) ->
        @sut.do @request, (error, @response) => done error

      it 'should have no keys in redis', (done) ->
        @client.keys '*', (error, result) ->
          expect(result.length).to.equal 0
          done()

      it 'should return a 204', ->
        expectedResponse =
          metadata:
            responseId: 'its-electric'
            code: 204
            status: 'No Content'

        expect(@response).to.deep.equal expectedResponse

    context 'when the rate is set low and messaged again', ->
      before (done) ->
        @client.hset @sut.getMinuteKey(), 'electric-eels', @sut.msgRateLimit/2, done

      before (done) ->
        @sut.do @request, (error, @response) => done error

      it 'should return a 204', ->
        expectedResponse =
          metadata:
            responseId: 'its-electric'
            code: 204
            status: 'No Content'

        expect(@response).to.deep.equal expectedResponse

      context 'when given another message with an "as" in auth', ->
        before (done) ->
          @request =
            metadata:
              responseId: 'its-electric'
              auth:
                uuid: 'atomic-clams'
                as: 'electric-eels'
              messageType: 'received'
              options: {}
            rawData: '{}'

          @sut.do @request, (error, @response) => done error

        it 'should return a 204', ->
          expectedResponse =
            metadata:
              responseId: 'its-electric'
              code: 204
              status: 'No Content'

          expect(@response).to.deep.equal expectedResponse

    context 'when the rate is set high and messaged again', ->
      before (done) ->
        @client.hset @sut.getMinuteKey(), 'electric-eels', @sut.msgRateLimit, done

      before (done) ->
        @sut.do @request, (error, @response) => done error

      it 'should return a 429', ->
        expectedResponse =
          metadata:
            responseId: 'its-electric'
            code: 429
            status: 'Too Many Requests'

        expect(@response).to.deep.equal expectedResponse

      context 'when given another message with an "as" in auth', ->
        before (done) ->
          @request =
            metadata:
              responseId: 'its-electric'
              auth:
                uuid: 'atomic-clams'
                as: 'electric-eels'
              messageType: 'received'
              options: {}
            rawData: '{}'

          @sut.do @request, (error, @response) => done error

        it 'should return a 429', ->
          expectedResponse =
            metadata:
              responseId: 'its-electric'
              code: 429
              status: 'Too Many Requests'

          expect(@response).to.deep.equal expectedResponse
