require 'angular'
require 'angular-mocks'
require 'angular-ui-router'
require '../common/auth/auth-module'
AddFriendsSignupCtrl = require './add-friends-signup-controller'

describe 'add friends during signup controller', ->
  $q = null
  $state = null
  Auth = null
  ctrl = null
  deferred = null
  scope = null
  User = null

  beforeEach angular.mock.module('down.auth')

  beforeEach angular.mock.module('ui.router')

  beforeEach inject(($injector) ->
    $controller = $injector.get '$controller'
    $rootScope = $injector.get '$rootScope'
    $q = $injector.get '$q'
    $state = $injector.get '$state'
    Auth = angular.copy $injector.get('Auth')
    scope = $rootScope.$new true
    User = $injector.get 'User'

    deferred = $q.defer()
    spyOn(User, 'getFacebookFriends').and.returnValue {$promise: deferred.promise}

    ctrl = $controller AddFriendsSignupCtrl,
      Auth: Auth
      $scope: scope
  )

  xit 'should request the user\'s facebook friends', ->
    expect(User.getFacebookFriends).toHaveBeenCalled()

  xdescribe 'when the facebook friends request returns', ->

    describe 'successfully', ->
      friend = null

      beforeEach ->
        friend = new User
          id: 1
          name: 'Alan Turing'
          username: 'tdog'
          imageUrl: 'https://graph.facebook.com/2.2/1598714293871/picture'
        deferred.resolve [friend]
        scope.$apply()

      it 'should generate the items list', ->
        items = [
          isDivider: true
          title: 'Friends Using Down'
        ,
          isDivider: false
          id: friend.id
          name: friend.name
          username: friend.username
          imageUrl: friend.imageUrl
        ,
          isDivider: true
          title: 'Contacts'
        ]
        expect(ctrl.items).toEqual items


    describe 'with an error', ->

      beforeEach ->
        deferred.reject()
        scope.$apply()

      it 'should show an error', ->
        expect(ctrl.fbFriendsRequestError).toBe true


  describe 'when the user finishes', ->

    beforeEach ->
      spyOn $state, 'go'

      ctrl.done()

    it 'should go to the events view', ->
      expect($state.go).toHaveBeenCalledWith 'events'
