class EventsCtrl
  @$inject: ['$meteor', '$rootScope', '$scope', '$state', 'Auth', 'Points',
             'SavedEvent', 'RecommendedEvent', 'ngToast', 'User', 'Event',
             '$mixpanel']
  constructor: (@$meteor, @$rootScope, @$scope, @$state, @Auth, @Points,
                @SavedEvent, @RecommendedEvent, @ngToast, @User,
                @Event, @$mixpanel) ->
    @items = []
    @commentsCount = {}
    @currentUser = @Auth.user

    # Set this function on the root scope so that it can be called from index.html.
    @$rootScope.setHasLearnedSaveEvent = @setHasLearnedSaveEvent

    @$scope.$on '$ionicView.loaded', =>
      @isLoading = true
      @refresh()

  handleLoadedData: ->
    if @savedEventsLoaded and @recommendedEventsLoaded \
        and @commentsCountLoaded
      @items = @buildItems()
      @isLoading = false
      @$scope.$broadcast 'scroll.refreshComplete'
      @optionallyShowWalkthrough()

  refresh: ->
    delete @savedEventsLoaded
    delete @recommendedEventsLoaded
    delete @commentsCountLoaded

    @getSavedEvents()
    @getRecommendedEvents()

  buildItems: ->
    items = []

    if @savedEvents.length > 0
      items.push
        isDivider: true
        title: 'Friends'

    recommendedEventsMap = {}
    for savedEvent in @savedEvents
      items.push
        isDivider: false
        savedEvent: savedEvent
        commentsCount: @commentsCount[savedEvent.eventId]

      recommendedEvent = savedEvent.event?.recommendedEvent
      if angular.isDefined recommendedEvent
        recommendedEventsMap[recommendedEvent] = true

    recommendedEventItems = []
    for recommendedEvent in @recommendedEvents
      if recommendedEventsMap[recommendedEvent.id] is undefined
        recommendedEventItems.push
          isDivider: false
          recommendedEvent: recommendedEvent

    if recommendedEventItems.length > 0
      items.push
        isDivider: true
        title: 'Recommended'
      items = items.concat recommendedEventItems

    items

  getSavedEvents: ->
    @SavedEvent.query()
      .$promise.then (savedEvents) =>
        @savedEvents = savedEvents
        @savedEventsLoaded = true
        @getCommentsCount()
        @handleLoadedData()
      , =>
        @ngToast.create 'Oops.. an error occurred..'

  getRecommendedEvents: ->
    @RecommendedEvent.query()
      .$promise.then (recommendedEvents) =>
        @recommendedEvents = recommendedEvents
        @recommendedEventsLoaded = true
        @handleLoadedData()
      , =>
        @ngToast.create 'Oops.. an error occurred..'

  getCommentsCount: ->
    eventIds = (savedEvent.eventId for savedEvent in @savedEvents)
    @$meteor.call 'getCommentsCount', eventIds
      .then (commentsCount) =>
        for countObj in commentsCount
          @commentsCount[countObj._id] = countObj.count
        @commentsCountLoaded = true
        @handleLoadedData()
      , =>
        @ngToast.create 'Oops.. an error occurred..'

  createEvent: ->
    @$state.go 'createEvent'

  saveRecommendedEvent: (recommendedEvent) ->
    event = angular.copy recommendedEvent
    event.recommendedEvent = recommendedEvent.id
    delete event.id
    recommendedEvent.wasSaved = true
    @Event.save event
      .$promise.then =>
        @$mixpanel.track 'Create Event',
          'from recommended': true
          'has place': angular.isDefined recommendedEvent.place
          'has time': angular.isDefined recommendedEvent.datetime
      , =>
        delete recommendedEvent.wasSaved
        @ngToast.create 'Oops.. an error occurred..'

  getItemHeight: (item) ->
    if item.isDivider
      26
    else if item.savedEvent
      item.savedEvent.getCellHeight()
    else if item.recommendedEvent
      item.recommendedEvent.getCellHeight()

  viewEvent: (savedEvent) ->
    @$state.go 'event',
      savedEvent: savedEvent
      commentsCount: @commentsCount[savedEvent.eventId]

  optionallyShowWalkthrough: ->
    if not @Auth.flags.hasLearnedSaveEvent
      @$rootScope.showLearnSaveEventPopover = true
    else if not @Auth.flags.hasLearnedFeed and @savedEvents.length > 0
      @showLearnFeedPopover = true

  setHasLearnedFeed: ->
    @Auth.setFlag 'hasLearnedFeed', true
    @showLearnFeedPopover = false

  # We need the => to call functions from this controller's scope because this
  # function is called from the root scope.
  setHasLearnedSaveEvent: =>
    @Auth.setFlag 'hasLearnedSaveEvent', true
    @$rootScope.showLearnSaveEventPopover = false
    @optionallyShowWalkthrough()

module.exports = EventsCtrl
