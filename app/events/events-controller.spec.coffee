require 'angular'
require 'angular-mocks'
require 'angular-ui-router'
require 'ng-toast'
require '../common/meteor/meteor-mocks'
EventsCtrl = require './events-controller'

describe 'events controller', ->
  $q = null
  $state = null
  $meteor = null
  Auth = null
  commentsCollection = null
  ctrl = null
  SavedEvent = null
  scope = null
  ngToast = null
  RecommendedEvent = null

  beforeEach angular.mock.module('ui.router')

  beforeEach angular.mock.module('rallytap.resources')

  beforeEach angular.mock.module('angular-meteor')

  beforeEach angular.mock.module('ngToast')

  beforeEach inject(($injector) ->
    $controller = $injector.get '$controller'
    $q = $injector.get '$q'
    $state = $injector.get '$state'
    $meteor = $injector.get '$meteor'
    Auth = $injector.get 'Auth'
    SavedEvent = $injector.get 'SavedEvent'
    scope = $injector.get '$rootScope'
    ngToast = $injector.get 'ngToast'
    RecommendedEvent = $injector.get 'RecommendedEvent'

    ctrl = $controller EventsCtrl,
      $scope: scope
  )

  ##$ionicView.loaded
  describe 'the first time that the view is loaded', ->

    beforeEach ->
      spyOn ctrl, 'refresh'

      scope.$emit '$ionicView.loaded'
      scope.$apply()

    it 'should refresh the data', ->
      expect(ctrl.refresh).toHaveBeenCalled()


  ##handleLoadedData
  describe 'handling after new data loads', ->
    items = null

    beforeEach ->
      items = []
      spyOn(ctrl, 'buildItems').and.returnValue items

    describe 'when all of the data has loaded', ->

      beforeEach ->
        ctrl.isLoading = true
        ctrl.savedEventsLoaded = true
        ctrl.recommendedEventsLoaded = true

        ctrl.handleLoadedData()

      it 'should remove the isLoading flag', ->
        expect(ctrl.isLoading).toBe undefined

      it 'should build the items', ->
        expect(ctrl.buildItems).toHaveBeenCalled()

      it 'should set the items on the controller', ->
        expect(ctrl.items).toBe items


  ##refresh
  describe 'pull to refresh', ->

    beforeEach ->
      ctrl.savedEventsLoaded = true
      ctrl.recommendedEventsLoaded = true

      spyOn ctrl, 'getSavedEvents'
      spyOn ctrl, 'getRecommendedEvents'

      ctrl.refresh()

    it 'should set the isLoading flag', ->
      expect(ctrl.isLoading).toBe true

    it 'should clear the loaded flags', ->
      expect(ctrl.savedEventsLoaded).toBe undefined
      expect(ctrl.recommendedEventsLoaded).toBe undefined

    it 'should get the events', ->
      expect(ctrl.getSavedEvents).toHaveBeenCalled()

    it 'should get the recommended events', ->
      expect(ctrl.getRecommendedEvents).toHaveBeenCalled()



  ##buildItems
  describe 'building the items', ->


  ##getSavedEvents
  describe 'getting the feed of events', ->
    deferred = null

    beforeEach ->
      deferred = $q.defer()
      spyOn(SavedEvent, 'query').and.returnValue {$promise: deferred.promise}

      ctrl.getSavedEvents()

    it 'should query saved events from the server', ->
      expect(SavedEvent.query).toHaveBeenCalled()

    describe 'when successful', ->
      response = null

      beforeEach ->
        spyOn ctrl, 'handleLoadedData'
        response = []

        deferred.resolve response
        scope.$apply()

      it 'should set the saved events on the controller', ->
        expect(ctrl.savedEvents).toBe response

      it 'should set the events loaded flag', ->
        expect(ctrl.savedEventsLoaded).toBe true

      it 'should handle the loaded data', ->
        expect(ctrl.handleLoadedData).toHaveBeenCalled()


    describe 'on error', ->

      beforeEach ->
        spyOn ngToast, 'create'

        deferred.reject()
        scope.$apply()

      it 'should show an error', ->
        expect(ngToast.create).toHaveBeenCalledWith 'Oops.. an error occurred..'


  ##getRecommendedEvents
  describe 'getting the recommended events', ->
    deferred = null

    beforeEach ->
      deferred = $q.defer()
      spyOn(RecommendedEvent, 'query') \
        .and.returnValue {$promise: deferred.promise}

      ctrl.getRecommendedEvents()

    it 'should query for the recommended events', ->
      expect(RecommendedEvent.query).toHaveBeenCalled()

    describe 'when successful', ->
      response = null

      beforeEach ->
        response = []
        spyOn ctrl, 'handleLoadedData'

        deferred.resolve response
        scope.$apply()

      it 'should set the recommended events on the controller', ->
        expect(ctrl.recommendedEvents).toBe response

      it 'should set the recommended events loaded flag', ->
        expect(ctrl.recommendedEventsLoaded).toBe true

      it 'should handle the data', ->
        expect(ctrl.handleLoadedData).toHaveBeenCalled()


    describe 'on error', ->

      beforeEach ->
        spyOn ngToast, 'create'

        deferred.reject()
        scope.$apply()

      it 'should show an error', ->
        expect(ngToast.create).toHaveBeenCalledWith 'Oops.. an error occurred..'


  ##saveEvent
  describe 'saving an event', ->
    deferred = null
    event = null
    item = null
    savedEvent = null

    beforeEach ->
      Auth.user =
        id: 1
      event =
        id: 1
      savedEvent =
        event: event
        eventId: event.id
        userId: 4
      item =
        savedEvent: savedEvent

      deferred = $q.defer()
      spyOn(SavedEvent, 'save').and.returnValue {$promise: deferred.promise}

      ctrl.saveEvent item

    it 'should create a new SavedEvent object', ->
      expect(SavedEvent.save).toHaveBeenCalledWith
        userId: Auth.user.id
        eventId: event.id

    describe 'when the save succeeds', ->
      interestedFriends = null

      beforeEach ->
        interestedFriends = ['friend1', 'friend2']
        newSavedEvent = angular.extend {}, savedEvent,
          interestedFriends: interestedFriends

        deferred.resolve newSavedEvent
        scope.$apply()

      it 'should set the interested friends on the item', ->
        expect(item.savedEvent.interestedFriends).toBe interestedFriends


    describe 'on error', ->

      beforeEach ->
        deferred.reject()
        scope.$apply()

      it 'should show an error', ->
        expect(item.saveError).toBe true


  ##isUserSavedEvent
  describe 'checking if the currrent user saved the event', ->
    savedEvent = null
    
    beforeEach ->
      savedEvent =
        id: 1
        event: 'some event'
        user: 'a user'
        interestedFriends: ['friend1', 'friend2']

    describe 'when the user has saved the event', ->

      it 'should return true', ->
        expect(ctrl.isUserSavedEvent(savedEvent)).toBe true


    describe 'when the user has not saved the event', ->

      beforeEach ->
        delete savedEvent.interestedFriends

      it 'should return false', ->
        expect(ctrl.isUserSavedEvent(savedEvent)).toBe false
      




  