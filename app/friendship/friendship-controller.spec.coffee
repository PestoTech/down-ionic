require 'angular'
require 'angular-mocks'
require '../common/auth/auth-module'
require '../common/mixpanel/mixpanel-module'
require '../common/meteor/meteor-mocks'
FriendshipCtrl = require './friendship-controller'

describe 'friendship controller', ->
  $meteor = null
  $mixpanel = null
  Auth = null
  ctrl = null
  friend = null
  Friendship = null
  Invitation = null
  scope = null
  User = null

  beforeEach angular.mock.module('angular-meteor')

  beforeEach angular.mock.module('analytics.mixpanel')

  beforeEach angular.mock.module('down.resources')

  beforeEach angular.mock.module('down.auth')

  beforeEach inject(($injector) ->
    $controller = $injector.get '$controller'
    $meteor = $injector.get '$meteor'
    $mixpanel = $injector.get '$mixpanel'
    $stateParams = angular.copy $injector.get('$stateParams')
    Auth = angular.copy $injector.get('Auth')
    Invitation = $injector.get 'Invitation'
    Friendship = $injector.get 'Friendship'
    scope = $injector.get '$rootScope'
    User = $injector.get 'User'

    Auth.user =
      id: 2
      name: 'Alan Turing'
      username: 'tdog'
      imageUrl: 'https://facebook.com/profile-pics/tdog'
      location:
        lat: 40.7265834
        long: -73.9821535
    friend =
      id: 1
      email: 'benihana@gmail.com'
      name: 'Benny Hana'
      username: 'benihana'
      imageUrl: 'https://facebook.com/profile-pics/benihana'
      location:
        lat: 40.7265834
        long: -73.9821535
    $stateParams.friend = friend

    ctrl = $controller FriendshipCtrl,
      $scope: scope
      $stateParams: $stateParams
      Auth: Auth
  )

  it 'should set the friend on the controller', ->
    expect(ctrl.friend).toBe friend

  describe 'checking whether a message is an action message', ->
    message = null

    beforeEach ->
      creator =
        id: 2
        name: 'Guido van Rossum'
        imageUrl: 'http://facebook.com/profile-pics/vrawesome'
      message =
        _id: 1
        creator: new User creator
        createdAt:
          $date: new Date().getTime()
        text: 'I\'m in love with a robot.'
        groupId: '1,2'
        type: 'text'

    describe 'when it is an accept action', ->

      beforeEach ->
        message.type = Invitation.acceptAction

      it 'should return true', ->
        expect(ctrl.isActionMessage message).toBe true


    describe 'when it is an maybe action', ->

      beforeEach ->
        message.type = Invitation.maybeAction

      it 'should return true', ->
        expect(ctrl.isActionMessage message).toBe true


    describe 'when it is a decline action', ->

      beforeEach ->
        message.type = Invitation.declineAction

      it 'should return true', ->
        expect(ctrl.isActionMessage message).toBe true


    describe 'when it\'s text', ->

      beforeEach ->
        message.type = 'text'

      it 'should return false', ->
        expect(ctrl.isActionMessage message).toBe false


  describe 'checking whether a message is the current user\'s message', ->
    message = null

    beforeEach ->
      creator =
        id: 2
        name: 'Guido van Rossum'
        imageUrl: 'http://facebook.com/profile-pics/vrawesome'
      message =
        _id: 1
        creator: new User creator
        createdAt:
          $date: new Date().getTime()
        text: 'I\'m in love with a robot.'
        groupId: '1,2'
        type: 'text'

    describe 'when it is', ->

      beforeEach ->
        message.creator.id = "#{Auth.user.id}" # Meteor likes strings

      it 'should return true', ->
        expect(ctrl.isMyMessage message).toBe true


    describe 'when it isn\'t', ->

      beforeEach ->
        message.creator.id = "#{Auth.user.id + 1}" # Meteor likes strings

      it 'should return false', ->
        expect(ctrl.isMyMessage message).toBe false


  describe 'sending a message', ->
    message = null

    beforeEach ->
      message = 'this is gonna be dope!'
      ctrl.message = message
      spyOn Friendship, 'sendMessage'
      spyOn $mixpanel, 'track'

      ctrl.sendMessage()

    it 'should send the message', ->
      expect(Friendship.sendMessage).toHaveBeenCalledWith ctrl.friend, message

    it 'should track Sent message in Mixpanel', ->
      expect($mixpanel.track).toHaveBeenCalledWith 'Send Message',
        to: 'friend'

    it 'should clear the message', ->
      expect(ctrl.message).toBeNull()


  describe 'once the view loads', ->
    chatId = null
    chat = null
    message = null
    messages = null

    beforeEach ->
      chatId = '1,2'
      spyOn(Friendship, 'getChatId').and.returnValue chatId
      chat = 'chat'
      scope.$meteorSubscribe = jasmine.createSpy '$scope.$meteorSubscribe'
        .and.returnValue chat
      message =
        _id: 1
        creator: new User Auth.user
        createdAt:
          $date: new Date().getTime()
        text: 'I\'m in love with a robot.'
        chatId: chatId
        type: 'text'
      messages = [message]
      $meteor.collection.and.returnValue messages

      scope.$emit '$ionicView.enter'
      scope.$apply()

    it 'should get the chat id', ->
      expect(Friendship.getChatId).toHaveBeenCalledWith ctrl.friend.id

    it 'should set the chat id on the controller', ->
      expect(ctrl.chatId).toBe chatId

    it 'should subscribe to the events messages', ->
      chatId = "#{friend.id},#{Auth.user.id}"
      expect(scope.$meteorSubscribe).toHaveBeenCalledWith 'chat', chatId

    it 'should set the chat subscription on the controller', ->
      expect(ctrl.chat).toBe chat

    it 'should get the messages', ->
      expect($meteor.collection).toHaveBeenCalledWith ctrl.getMessages, false

    it 'should bind the messages to the controller', ->
      expect(ctrl.messages).toBe messages

    describe 'when no messages were posted yet', ->

      beforeEach ->
        ctrl.messages = []
        scope.$apply()

      it 'should handle when there are no messages', ->


    describe 'when new messages get posted', ->
      message2 = null

      beforeEach ->
        message2 = angular.extend {}, message,
          _id: message._id+1
        messages.push message2
        scope.$apply()

      it 'should mark the message as read', ->
        expect($meteor.call).toHaveBeenCalledWith 'readMessage', message2._id


  describe 'when leaving the view', ->

    beforeEach ->
      ctrl.messages =
        stop: jasmine.createSpy 'messages.stop'
      ctrl.chat =
        stop: jasmine.createSpy 'chat.stop'

      scope.$broadcast '$ionicView.leave'
      scope.$apply()

    it 'should stop the angular-meteor bindings', ->
      expect(ctrl.messages.stop).toHaveBeenCalled()
      expect(ctrl.chat.stop).toHaveBeenCalled()


  describe 'getting messages', ->
    cursor = null
    messages = null

    beforeEach ->
      ctrl.chatId = '1,2'
      cursor = 'messagesCursor'
      ctrl.Messages =
        find: jasmine.createSpy('Messages.find').and.returnValue cursor
      messages = ctrl.getMessages()

    it 'should query, sort and transform messages', ->
      selector =
        chatId: ctrl.chatId
      options =
        sort:
          createdAt: 1
        transform: ctrl.transformMessage
      expect(ctrl.Messages.find).toHaveBeenCalledWith selector, options

    it 'should return a messages reactive cursor', ->
      expect(messages).toBe cursor


  describe 'transforming messages', ->
    message = null
    transformedMessage = null

    beforeEach ->
      message =
        creator: {}
      transformedMessage = ctrl.transformMessage message

    it 'should create a new User object with the message.creator', ->
      messageCopy = angular.copy message
      messageCopy.creator = new User messageCopy.creator
      expect(transformedMessage).toEqual messageCopy
