RecommendedEvent = ['$resource', 'apiRoot', ($resource, apiRoot) ->
  listUrl = "#{apiRoot}/recommended-events"

  serializeRecommendedEvent = (recommendedEvent) ->

  deserializeRecommendedEvent = (data) ->

  resource = $resource "#{listUrl}/:id", null,
    query: {}

  resource.listUrl = listUrl

  resource.serialize = serializeRecommendedEvent
  resource.deserialize = deserializeRecommendedEvent

  resource
]

module.exports = RecommendedEvent
