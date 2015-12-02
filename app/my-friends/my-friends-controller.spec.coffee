require '../ionic/ionic.js'
require 'angular'
require 'angular-mocks'
require 'angular-sanitize'
require 'angular-ui-router'
require '../ionic/ionic-angular.js'
window.$ = window.jQuery = require 'jquery'
require '../common/auth/auth-module'
require '../common/intl-phone/intl-phone-module'
MyFriendsCtrl = require './my-friends-controller'

describe 'MyFriends controller', ->
  $ionicHistory = null
  $state = null
  Auth = null
  ctrl = null
  scope = null

  beforeEach angular.mock.module('ionic')

  beforeEach angular.mock.module('rallytap.auth')

  beforeEach angular.mock.module('rallytap.intlPhone')

  beforeEach angular.mock.module('ui.router')

  beforeEach inject(($injector) ->
    $controller = $injector.get '$controller'
    $ionicHistory = $injector.get '$ionicHistory'
    $state = $injector.get '$state'
    Auth = $injector.get 'Auth'
    scope = $injector.get '$rootScope'

    # Mock the logged in user.
    Auth.user =
      id: 1
      email: 'aturing@gmail.com'
      name: 'Alan Turing'
      username: 'tdog'
      imageUrl: 'https://facebook.com/profile-pics/tdog'
      location:
        lat: 40.7265834
        long: -73.9821535
    Auth.phone = '+19178233560'

    # Mock the user's friends.
    Auth.user.friends =
      2:
        id: 2
        email: 'ltorvalds@gmail.com'
        name: 'Linus Torvalds'
        username: 'valding'
        imageUrl: 'https://facebook.com/profile-pics/valding'
        location:
          lat: 40.7265834 # just under 5 mi away
          long: -73.9821535
      3:
        id: 3
        email: 'jclarke@gmail.com'
        name: 'Joan Clarke'
        username: 'jnasty'
        imageUrl: 'https://facebook.com/profile-pics/jnasty'
        location:
          lat: 40.7265834 # just under 5 mi away
          long: -73.9821535
      4:
        id: 4
        email: 'gvrossum@gmail.com'
        name: 'Guido van Rossum'
        username: 'vrawesome'
        imageUrl: 'https://facebook.com/profile-pics/vrawesome'
        location:
          lat: 40.79893 # just over 5 mi away
          long: -73.9821535
      5:
        id: 5
        name: '+19252852230'

    ctrl = $controller MyFriendsCtrl,
      $scope: scope
      Auth: Auth
  )

  it 'should set the user\'s friends on the controller', ->
    items = [
      isDivider: true
      title: 'Nearby Friends'
    ]
    for friend in ctrl.nearbyFriends
      items.push
        isDivider: false
        friend: friend
    friends = Auth.user.friends
    alphabeticalItems = [
      isDivider: true
      title: friends[4].name[0]
    ,
      isDivider: false
      friend: friends[4]
    ,
      isDivider: true
      title: friends[3].name[0]
    ,
      isDivider: false
      friend: friends[3]
    ,
      isDivider: true
      title: friends[2].name[0]
    ,
      isDivider: false
      friend: friends[2]
    ,
      isDivider: true
      title: 'Added by phone #'
    ,
      isDivider: false
      friend: friends[5]
    ]
    for item in alphabeticalItems
      items.push item
    expect(ctrl.items).toEqual items

  it 'should set the user\'s phone number on the controller', ->
    expect(ctrl.myPhone).toBe Auth.phone

  describe 'getting a user\'s initials', ->

    describe 'when they have multiple words in their name', ->

      it 'should return the first letter of their first and last name', ->
        expect(ctrl.getInitials 'Alan Tdog Turing').toBe 'AT'


    describe 'when they have one word in their name', ->

      it 'should return the first two letters of their name', ->
        expect(ctrl.getInitials 'Pele').toBe 'PE'


    describe 'when they have one letter in their name', ->

      it 'should return the first letter of their name', ->
        expect(ctrl.getInitials 'p').toBe 'P'


  describe 'adding friends', ->

    beforeEach ->
      spyOn $ionicHistory, 'nextViewOptions'
      spyOn $state, 'go'

      ctrl.addFriends()

    it 'should disable animating the transition to the next view', ->
      options = {disableAnimate: true}
      expect($ionicHistory.nextViewOptions).toHaveBeenCalledWith options

    it 'should go to the add friends view', ->
      expect($state.go).toHaveBeenCalledWith 'tabs.friends.addFriends'


  ##isPhone
  describe 'checking whether a name is a phone number', ->
    isPhone = null

    describe 'when it is', ->

      beforeEach ->
        isPhone = ctrl.isPhone '+19178233560'

      it 'should return true', ->
        expect(isPhone).toBe true


    describe 'when it isn\'t', ->

      beforeEach ->
        isPhone = ctrl.isPhone 'Joey Baggadonuts'

      it 'should return false', ->
        expect(isPhone).toBe false
