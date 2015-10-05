require 'angular'
require 'angular-mocks'
require 'ng-toast'
require '../common/auth/auth-module'
require '../common/mixpanel/mixpanel-module'
require '../common/meteor/meteor-mocks'
FriendshipCtrl = require './friendship-controller'

describe 'friendship controller', ->
  $ionicLoading = null
  $meteor = null
  $mixpanel = null
  $q = null
  $state = null
  Auth = null
  chatsCollection = null
  ctrl = null
  friend = null
  Friendship = null
  Invitation = null
  messagesCollection = null
  ngToast = null
  scope = null
  User = null

  beforeEach angular.mock.module('angular-meteor')

  beforeEach angular.mock.module('analytics.mixpanel')

  beforeEach angular.mock.module('down.resources')

  beforeEach angular.mock.module('down.auth')

  beforeEach angular.mock.module('ionic')

  beforeEach angular.mock.module('ngToast')

  beforeEach inject(($injector) ->
    $controller = $injector.get '$controller'
    $ionicLoading = $injector.get '$ionicLoading'
    $meteor = $injector.get '$meteor'
    $mixpanel = $injector.get '$mixpanel'
    $q = $injector.get '$q'
    $state = $injector.get '$state'
    $stateParams = angular.copy $injector.get('$stateParams')
    Auth = angular.copy $injector.get('Auth')
    Invitation = $injector.get 'Invitation'
    Friendship = $injector.get 'Friendship'
    ngToast = $injector.get 'ngToast'
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

    messagesCollection = 'messagesCollection'
    chatsCollection = 'chatsCollection'
    $meteor.getCollectionByName.and.callFake (collectionName) ->
      if collectionName is 'messages' then return messagesCollection
      if collectionName is 'chats' then return chatsCollection

    ctrl = $controller FriendshipCtrl,
      $scope: scope
      $stateParams: $stateParams
      Auth: Auth
  )

  it 'should set the friend on the controller', ->
    expect(ctrl.friend).toBe friend

  it 'should set the messages collection on the controller', ->
    expect($meteor.getCollectionByName).toHaveBeenCalledWith 'messages'
    expect(ctrl.Messages).toBe messagesCollection

  it 'should set the events collection on the controller', ->
    expect($meteor.getCollectionByName).toHaveBeenCalledWith 'chats'
    expect(ctrl.Chats).toBe chatsCollection

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


  describe 'checking whether a message is an invite action message', ->
    message = null

    beforeEach ->
      message =
        _id: 1
        creator: new User {id: 2}
        createdAt:
          $date: new Date().getTime()
        text: 'I\'m in love with a robot.'
        groupId: '1,2'
        type: 'text'

    describe 'when it is an invite action', ->

      beforeEach ->
        message.type = Invitation.inviteAction

      it 'should return true', ->
        expect(ctrl.isInviteAction message).toBe true


    describe 'when it isn\'t an invite action', ->

      beforeEach ->
        message.type = Invitation.acceptAction

      it 'should return false', ->
        expect(ctrl.isInviteAction message).toBe false


  describe 'checking whether a message is a text message', ->
    message = null

    beforeEach ->
      message =
        _id: 1
        creator: new User {id: 2}
        createdAt:
          $date: new Date().getTime()
        text: 'I\'m in love with a robot.'
        groupId: '1,2'

    describe 'when it is a text message', ->

      beforeEach ->
        message.type = Invitation.textMessage

      it 'should return true', ->
        expect(ctrl.isTextMessage message).toBe true


    describe 'when it isn\'t a text message', ->

      beforeEach ->
        message.type = Invitation.inviteAction

      it 'should return false', ->
        expect(ctrl.isTextMessage message).toBe false


  describe 'checking whether an invitation is loading', ->
    message = null

    beforeEach ->
      message =
        _id: 1
        creator: new User {id: 2}
        createdAt:
          $date: new Date().getTime()
        text: 'I\'m in love with a robot.'
        groupId: '1,2'

    describe 'when it is has no invitation', ->

      beforeEach ->
        message.type = Invitation.inviteAction

      it 'should return true', ->
        expect(ctrl.isLoadingInvitation message).toBe true


    describe 'when it isn\'t a text message', ->

      beforeEach ->
        message.type = Invitation.inviteAction
        message.invitation = {id: 1}

      it 'should return false', ->
        expect(ctrl.isLoadingInvitation message).toBe false


  describe 'checking whether a message is an error message', ->
    message = null

    beforeEach ->
      message =
        _id: 1
        creator: new User {id: 2}
        createdAt:
          $date: new Date().getTime()
        text: 'I\'m in love with a robot.'
        groupId: '1,2'

    describe 'when it is an error message', ->

      beforeEach ->
        message.type = Invitation.errorAction

      it 'should return true', ->
        expect(ctrl.isErrorAction message).toBe true


    describe 'when it isn\'t an error message', ->

      beforeEach ->
        message.type = Invitation.inviteAction

      it 'should return false', ->
        expect(ctrl.isErrorAction message).toBe false


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


  describe 'checking whether the user accepted their invitation', ->
    invitation = null

    beforeEach ->
      invitation = {id: 1}

    describe 'when they did', ->

      beforeEach ->
        invitation.response = Invitation.accepted

      it 'should return true', ->
        expect(ctrl.isAccepted invitation).toBe true


    describe 'when they didn\'t', ->

      beforeEach ->
        invitation.response = Invitation.maybe

      it 'should return false', ->
        expect(ctrl.isAccepted invitation).toBe false


  describe 'checking whether the user responded maybe to their invitation', ->
    invitation = null

    beforeEach ->
      invitation = {id: 1}

    describe 'when they did', ->

      beforeEach ->
        invitation.response = Invitation.maybe

      it 'should return true', ->
        expect(ctrl.isMaybe invitation).toBe true


    describe 'when they didn\'t', ->

      beforeEach ->
        invitation.response = Invitation.accepted

      it 'should return false', ->
        expect(ctrl.isMaybe invitation).toBe false


  describe 'checking whether the user declined their invitation', ->
    invitation = null

    beforeEach ->
      invitation = {id: 1}

    describe 'when they did', ->

      beforeEach ->
        invitation.response = Invitation.declined

      it 'should return true', ->
        expect(ctrl.isDeclined invitation).toBe true


    describe 'when they didn\'t', ->

      beforeEach ->
        invitation.response = Invitation.accepted

      it 'should return false', ->
        expect(ctrl.isDeclined invitation).toBe false


  describe 'responding to an invitation', ->
    response = null
    invitation = null
    deferred = null
    newResponse = null

    beforeEach ->
      spyOn $ionicLoading, 'show'
      spyOn $ionicLoading, 'hide'

      # Mock the current invitation response.
      response = Invitation.noResponse
      invitation = new Invitation
        id: 1
        response: response
        event:
          id: 2

      deferred = $q.defer()
      spyOn(Invitation, 'updateResponse').and.returnValue
        $promise: deferred.promise

      newResponse = Invitation.accepted
      ctrl.respondToInvitation invitation, newResponse

    it 'should show a loading modal', ->
      expect($ionicLoading.show).toHaveBeenCalled()

    it 'should update the invitation', ->
      expect(Invitation.updateResponse).toHaveBeenCalledWith(invitation,
          newResponse)

    describe 'when the update succeeds', ->

      beforeEach ->
        spyOn $state, 'go'

      describe 'and the response is accepted', ->

        beforeEach ->
          invitation.response = Invitation.accepted
          deferred.resolve invitation
          scope.$apply()

        it 'should hide the loading overlay', ->
          expect($ionicLoading.hide).toHaveBeenCalled()

        it 'should go to the event chat', ->
          expect($state.go).toHaveBeenCalledWith 'event',
            invitation: invitation
            id: invitation.event.id


      describe 'and the response is maybe', ->

        beforeEach ->
          invitation.response = Invitation.maybe
          deferred.resolve invitation
          scope.$apply()

        it 'should hide the loading overlay', ->
          expect($ionicLoading.hide).toHaveBeenCalled()

        it 'should go to the event chat', ->
          expect($state.go).toHaveBeenCalledWith 'event',
            invitation: invitation
            id: invitation.event.id


      describe 'and the response is declined', ->

        beforeEach ->
          invitation.response = Invitation.declined
          deferred.resolve invitation
          scope.$apply()

        it 'should hide the loading overlay', ->
          expect($ionicLoading.hide).toHaveBeenCalled()


    describe 'when the update fails', ->

      beforeEach ->
        spyOn ngToast, 'create'

        deferred.reject()
        scope.$apply()

      it 'should hide the loading overlay', ->
        expect($ionicLoading.hide).toHaveBeenCalled()

      it 'show an error', ->
        error = 'For some reason, that didn\'t work.'
        expect(ngToast.create).toHaveBeenCalledWith error


  describe 'accepting an invitation', ->
    invitation = null

    beforeEach ->
      spyOn ctrl, 'respondToInvitation'

      invitation = {id: 1}
      ctrl.acceptInvitation invitation

    it 'should respond to the invitation', ->
      expect(ctrl.respondToInvitation).toHaveBeenCalledWith(invitation,
          Invitation.accepted)


  describe 'responding maybe an invitation', ->
    invitation = null

    beforeEach ->
      spyOn ctrl, 'respondToInvitation'

      invitation = {id: 1}
      ctrl.maybeInvitation invitation

    it 'should respond to the invitation', ->
      expect(ctrl.respondToInvitation).toHaveBeenCalledWith(invitation,
          Invitation.maybe)


  describe 'declining an invitation', ->
    invitation = null

    beforeEach ->
      spyOn ctrl, 'respondToInvitation'

      invitation = {id: 1}
      ctrl.declineInvitation invitation

    it 'should respond to the invitation', ->
      expect(ctrl.respondToInvitation).toHaveBeenCalledWith(invitation,
          Invitation.declined)


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
    message = null
    messages = null

    beforeEach ->
      chatId = '1,2'
      spyOn(Friendship, 'getChatId').and.returnValue chatId
      scope.$meteorSubscribe = jasmine.createSpy '$scope.$meteorSubscribe'
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
      spyOn ctrl, 'getFriendInvitations'

      scope.$emit '$ionicView.enter'
      scope.$apply()

    it 'should get the chat id', ->
      expect(Friendship.getChatId).toHaveBeenCalledWith ctrl.friend.id

    it 'should set the chat id on the controller', ->
      expect(ctrl.chatId).toBe chatId

    it 'should subscribe to the events messages', ->
      chatId = "#{friend.id},#{Auth.user.id}"
      expect(scope.$meteorSubscribe).toHaveBeenCalledWith 'chat', chatId

    it 'should get the messages', ->
      expect($meteor.collection).toHaveBeenCalledWith ctrl.getMessages, false

    it 'should bind the messages to the controller', ->
      expect(ctrl.messages).toBe messages

    it 'should request the invitations to/from the friend', ->
      expect(ctrl.getFriendInvitations).toHaveBeenCalled()

    describe 'when no messages were posted yet', ->

      beforeEach ->
        ctrl.messages = []
        scope.$apply()

      it 'should handle when there are no messages', ->


    describe 'when new messages get posted', ->
      message2 = null

      describe 'when the message isn\'t an invite action', ->

        beforeEach ->
          message2 = angular.extend {}, message,
            _id: message._id+1
            type: Invitation.acceptAction
          ctrl.messages.push message2
          scope.$apply()

        it 'should mark the message as read', ->
          expect($meteor.call).toHaveBeenCalledWith 'readMessage', message2._id

      describe 'when the message is an invite action', ->

        beforeEach ->
          ctrl.getFriendInvitations.calls.reset()

          message2 = angular.extend {}, message,
            _id: message._id+1
            type: Invitation.inviteAction
          ctrl.messages.push message2
          scope.$apply()

        it 'should mark the message as read', ->
          # TODO: Don't mark invite action messages as read until we fetch the
          #   invitation
          expect($meteor.call).toHaveBeenCalledWith 'readMessage', message2._id

        it 'should refresh the invitations', ->
          expect(ctrl.getFriendInvitations).toHaveBeenCalled()


  describe 'when leaving the view', ->

    beforeEach ->
      ctrl.messages =
        stop: jasmine.createSpy 'messages.stop'

      scope.$broadcast '$ionicView.leave'
      scope.$apply()

    it 'should stop the angular-meteor bindings', ->
      expect(ctrl.messages.stop).toHaveBeenCalled()


  describe 'getting the invitations to/from the friend', ->
    deferred = null
    eventId = null
    message1 = null
    message2 = null
    message3 = null

    beforeEach ->
      deferred = $q.defer()
      spyOn(Invitation, 'getUserInvitations').and.returnValue
        $promise: deferred.promise

      # Mock invite action messages.
      message =
        _id: 1
        creator: new User {id: 1}
        createdAt:
          $date: new Date().getTime()
        text: 'Down?'
        groupId: '1,2'
        type: Invitation.inviteAction
      eventId = 2
      message1 = angular.extend {}, message,
        meta:
          eventId: eventId
      message2 = angular.extend {}, message,
        meta:
          eventId: eventId+1 # This event is expired.
      message3 = angular.extend {}, message,
        type: Invitation.acceptAction
      ctrl.messages = [message1, message2, message3]

      ctrl.getFriendInvitations()

    it 'should request the invitations from the server', ->
      expect(Invitation.getUserInvitations).toHaveBeenCalledWith ctrl.friend.id

    describe 'successfully', ->
      invitation = null

      beforeEach ->
        ctrl.messages.remove = jasmine.createSpy 'messages.remove'

        invitation = new Invitation
          id: 1
          eventId: eventId
          fromUserId: Auth.user.id
          toUserId: friend.id
        deferred.resolve [invitation]
        scope.$apply()

      it 'should set the invitation on the message', ->
        expect(message1.invitation).toBe invitation

      it 'should delete expired invite_action messages', ->
        expect(ctrl.messages.remove).toHaveBeenCalledWith message2._id

    describe 'unsuccessfully', ->

      beforeEach ->
        deferred.reject()
        scope.$apply()

      it 'should update the messages\' types', ->
        message1Copy = angular.extend {}, message1,
          type: Invitation.errorAction
        message2Copy = angular.extend {}, message2,
          type: Invitation.errorAction
        expect(ctrl.messages).toEqual [message1Copy, message2Copy, message3]


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


  describe 'viewing an event', ->
    invitation = null

    beforeEach ->
      spyOn $state, 'go'

      invitation =
        id: 1
        event:
          id: 2
      ctrl.viewEvent invitation

    it 'should go to the event', ->
      expect($state.go).toHaveBeenCalledWith 'event',
        invitation: invitation
        id: invitation.event.id
