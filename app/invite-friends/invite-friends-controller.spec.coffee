require '../ionic/ionic.js'
require 'angular'
require 'angular-mocks'
require 'angular-sanitize'
require 'angular-ui-router'
require '../ionic/ionic-angular.js'
require '../common/auth/auth-module'
require '../common/resources/resources-module'
require '../common/local-db/local-db-module'
require '../common/mixpanel/mixpanel-module'
InviteFriendsCtrl = require './invite-friends-controller'

describe 'invite friends controller', ->
  $controller = null
  $ionicHistory = null
  $ionicLoading = null
  $q = null
  $state = null
  $mixpanel = null
  Auth = null
  contacts = null
  ctrl = null
  event = null
  Event = null
  Invitation = null
  LocalDB = null
  scope = null

  beforeEach angular.mock.module('analytics.mixpanel')

  beforeEach angular.mock.module('ionic')

  beforeEach angular.mock.module('ui.router')

  beforeEach angular.mock.module('rallytap.auth')

  beforeEach angular.mock.module('rallytap.resources')

  beforeEach angular.mock.module('rallytap.localDB')

  beforeEach inject(($injector) ->
    $controller = $injector.get '$controller'
    $ionicHistory = $injector.get '$ionicHistory'
    $ionicLoading = $injector.get '$ionicLoading'
    $q = $injector.get '$q'
    $state = angular.copy $injector.get('$state')
    $mixpanel = $injector.get '$mixpanel'
    Auth = $injector.get 'Auth'
    Event = $injector.get 'Event'
    Invitation = $injector.get 'Invitation'
    LocalDB = $injector.get 'LocalDB'
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
    Auth.user.facebookFriends =
      4: Auth.user.friends[4]
    contacts =
      2: Auth.user.friends[2]
      3: Auth.user.friends[3]

    # Mock the event being created.
    event =
      title: 'bars?!?!!?'
      creator: 2
      canceled: false
      datetime: new Date()
      createdAt: new Date()
      updatedAt: new Date()
      place:
        name: 'B Bar & Grill'
        lat: 40.7270718
        long: -73.9919324
    $state.params.event = event

    spyOn(Auth, 'isNearby').and.callFake (friend) ->
      friend.id in [Auth.user.friends[2].id, Auth.user.friends[3].id]

    ctrl = $controller InviteFriendsCtrl,
      $scope: scope
      Auth: Auth
      $state: $state
  )

  it 'should init the array of selected friends', ->
    expect(ctrl.selectedFriends).toEqual []

  it 'should init the dictionary of selected friend ids', ->
    expect(ctrl.selectedFriendIds).toEqual {}

  it 'should init the array of invited ids', ->
    expect(ctrl.invitedUserIds).toEqual {}

  describe 'when entering the view', ->
    deferred = null

    beforeEach ->
      ctrl.error = 'inviteError'

      spyOn ctrl, 'setupView'
      spyOn $ionicHistory, 'nextViewOptions'

      deferred = $q.defer()
      spyOn(LocalDB, 'get').and.returnValue deferred.promise

      scope.$broadcast '$ionicView.enter'
      scope.$apply()

    it 'should init cleanupViewAfterLeave', ->
      expect(ctrl.cleanupViewAfterLeave).toBe true

    it 'should set the event on the controller', ->
      expect(ctrl.event).toBe event

    it 'should disable animating the transition to the next view', ->
      options = {disableAnimate: true}
      expect($ionicHistory.nextViewOptions).toHaveBeenCalledWith options

    it 'should clear errors', ->
      expect(ctrl.error).toEqual false

    it 'should get contacts from the localdb', ->
      expect(LocalDB.get).toHaveBeenCalledWith 'contacts'

    describe 'when successful', ->

      beforeEach ->
        deferred.resolve contacts
        scope.$apply()

      it 'should set the contacts object on the controller', ->
        expect(ctrl.contacts).toBe contacts

      it 'should set up the view', ->
        expect(ctrl.setupView).toHaveBeenCalled()


    describe 'on localDB error', ->

      beforeEach ->
        deferred.reject()
        scope.$apply()

      it 'should show and error', ->
        expect(ctrl.error).toBe 'localDBError'



  describe 'after leaving the view', ->

    describe 'when cleanupViewAfterLeave is true', ->

      beforeEach ->
        ctrl.cleanupViewAfterLeave = true
        spyOn ctrl, 'cleanupView'

        scope.$broadcast '$ionicView.afterLeave'
        scope.$apply()

      it 'should clean up the view', ->
        expect(ctrl.cleanupView).toHaveBeenCalled()


  ##setupView
  describe 'setting up the view', ->

    describe 'when setting up the view for an existing event', ->

      beforeEach ->
        ctrl.event =
          id: 1
        spyOn ctrl, 'setupExistingEvent'

        ctrl.setupView()

      it 'should call setup existing event', ->
        expect(ctrl.setupExistingEvent).toHaveBeenCalled()


    describe 'when setting up the view for creating a new event', ->

      beforeEach ->
        ctrl.event = {}
        spyOn ctrl, 'setupNewEvent'

        ctrl.setupView()

      it 'should call setup existing event', ->
        expect(ctrl.setupNewEvent).toHaveBeenCalled()


  ##setupExistingEvent
  describe 'setting up the view for an existing event', ->
    deferred = null

    beforeEach ->
      # Mock event with an id.
      event =
        id: 1
        title: 'bars?!?!!?'
        creator: 2
        canceled: false
        datetime: new Date()
        createdAt: new Date()
        updatedAt: new Date()
        place:
          name: 'B Bar & Grill'
          lat: 40.7270718
          long: -73.9919324
      ctrl.event = event

      deferred = $q.defer()
      spyOn(Event, 'getInvitedIds').and.returnValue deferred.promise

      spyOn $ionicLoading, 'show'
      spyOn $ionicLoading, 'hide'

      ctrl.setupExistingEvent()

    it 'should show a loading indicator', ->
      expect($ionicLoading.show).toHaveBeenCalled()

    it 'should get invited ids', ->
      expect(Event.getInvitedIds).toHaveBeenCalledWith event

    describe 'getting invited ids', ->

      describe 'when successful', ->
        invitedUserIds = null

        describe 'with items', ->

          beforeEach ->
            spyOn(ctrl, 'buildItems').and.callFake ->
              # Mock there being items.
              ctrl.items = [
                isDivider: false
                friend: Auth.user.friends[2]
              ]

            invitedUserIds = [2]
            deferred.resolve invitedUserIds
            scope.$apply()

          it 'should save users\' ids who were invited', ->
            expectedIds = {}
            for id in invitedUserIds
              expectedIds[id] = true
            expect(ctrl.invitedUserIds).toEqual expectedIds

          it 'should call build items', ->
            expect(ctrl.buildItems).toHaveBeenCalled()

          it 'should hide the loading indicator', ->
            expect($ionicLoading.hide).toHaveBeenCalled()


        describe 'with no items', ->

          beforeEach ->
            spyOn(ctrl, 'buildItems').and.callFake ->
              # Mock there being items.
              ctrl.items = []

            invitedUserIds = [2]
            deferred.resolve invitedUserIds
            scope.$apply()

          it 'should hide the loading indicator', ->
            expect($ionicLoading.hide).toHaveBeenCalled()

          it 'should save users\' ids who were invited', ->
            expectedIds = {}
            for id in invitedUserIds
              expectedIds[id] = true
            expect(ctrl.invitedUserIds).toEqual expectedIds

          it 'should call build items', ->
            expect(ctrl.buildItems).toHaveBeenCalled()

          it 'should set a no items flag', ->
            expect(ctrl.noItems).toBe true


      describe 'when there is an error', ->

        beforeEach ->
          ctrl.getInvitedIdsError = false

          deferred.reject()
          scope.$apply()

        it 'should show an error', ->
          expect(ctrl.error).toBe 'getInvitedIdsError'

        it 'should hide the loading indicator', ->
          expect($ionicLoading.hide).toHaveBeenCalled()


  ##setupNewEvent
  describe 'setting up the view for a new event', ->

    describe 'with items', ->

      beforeEach ->
        spyOn(ctrl, 'buildItems').and.callFake ->
          # Mock there being items.
          ctrl.items = [
            isDivider: false
            friend: Auth.user.friends[2]
          ]
        ctrl.setupNewEvent()

      it 'should build the items array', ->
        expect(ctrl.buildItems).toHaveBeenCalled()


    describe 'with no items', ->

      beforeEach ->
        spyOn(ctrl, 'buildItems').and.callFake ->
          # Mock there being items.
          ctrl.items = []
        ctrl.setupNewEvent()

      it 'should set a no items flag', ->
        expect(ctrl.noItems).toBe true


  ##cleanupView
  describe 'cleaning up the view', ->

    beforeEach ->
      ctrl.event = 'some event object'
      ctrl.selectedFriends = ['friend 1', 'friend 2']
      ctrl.selectedFriendIds = {1: true, 2: true}
      ctrl.invitedUserIds = {1: true}
      ctrl.cleanupView()

    it 'should delete the event', ->
      expect(ctrl.event).toBeUndefined()

    it 'should clear selected friends', ->
      expect(ctrl.selectedFriends).toEqual []
      expect(ctrl.selectedFriendIds).toEqual {}

    it 'should clear invited user ids', ->
      expect(ctrl.invitedUserIds).toEqual {}


  ##buildItems
  describe 'building the items array', ->

    describe 'without a search query', ->

      beforeEach ->
        ctrl.query = ''

      describe 'when the user has contacts', ->

        beforeEach ->
          ctrl.contacts = contacts
          ctrl.buildItems()

        it 'should set the items on the controller', ->
          items = [
            isDivider: true
            title: 'Nearby Friends'
          ]
          for friend in ctrl.nearbyFriends
            items.push
              isDivider: false
              friend: friend
          alphabeticalItems = [
            isDivider: true
            title: Auth.user.friends[4].name[0]
          ,
            isDivider: false
            friend: Auth.user.friends[4]
          ,
            isDivider: true
            title: Auth.user.friends[3].name[0]
          ,
            isDivider: false
            friend: Auth.user.friends[3]
          ,
            isDivider: true
            title: Auth.user.friends[2].name[0]
          ,
            isDivider: false
            friend: Auth.user.friends[2]
          ]
          for item in alphabeticalItems
            items.push item
          items.push
            isDivider: true
            title: 'Facebook Friends'
          facebookFriendsItems = [
            isDivider: false
            friend: Auth.user.facebookFriends[4]
          ]
          for item in facebookFriendsItems
            items.push item
          items.push
            isDivider: true
            title: 'Contacts'
          contactsItems = [
            isDivider: false
            friend: contacts[3]
          ,
            isDivider: false
            friend: contacts[2]
          ]
          for item in contactsItems
            items.push item
          expect(ctrl.items).toEqual items

        it 'should save a sorted array of nearby friends', ->
          expect(ctrl.nearbyFriends).toEqual [ # Alphabetical
            Auth.user.friends[3]
            Auth.user.friends[2]
          ]

        it 'should save nearby friend ids', ->
          nearbyFriendIds = {}
          nearbyFriendIds[2] = true
          nearbyFriendIds[3] = true
          expect(ctrl.nearbyFriendIds).toEqual nearbyFriendIds


      describe 'when the user doesn\'t have contacts', ->

        beforeEach ->
          ctrl.contacts = {}
          ctrl.buildItems()

        it 'should set the items on the controller', ->
          items = [
            isDivider: true
            title: 'Nearby Friends'
          ]
          for friend in ctrl.nearbyFriends
            items.push
              isDivider: false
              friend: friend
          alphabeticalItems = [
            isDivider: true
            title: Auth.user.friends[4].name[0]
          ,
            isDivider: false
            friend: Auth.user.friends[4]
          ,
            isDivider: true
            title: Auth.user.friends[3].name[0]
          ,
            isDivider: false
            friend: Auth.user.friends[3]
          ,
            isDivider: true
            title: Auth.user.friends[2].name[0]
          ,
            isDivider: false
            friend: Auth.user.friends[2]
          ]
          for item in alphabeticalItems
            items.push item
          items.push
            isDivider: true
            title: 'Facebook Friends'
          facebookFriendsItems = [
            isDivider: false
            friend: Auth.user.facebookFriends[4]
          ]
          for item in facebookFriendsItems
            items.push item
          expect(ctrl.items).toEqual items


    describe 'with a search query', ->

      beforeEach ->
        ctrl.query = 'U'

        ctrl.buildItems()

      it 'should build the items array', ->
        items = [
          isDivider: false
          friend: Auth.user.friends[4]
        ,
          isDivider: false
          friend: Auth.user.friends[2]
        ]
        expect(ctrl.items).toEqual items


  describe 'toggling whether a friend is selected', ->
    friend = null

    beforeEach ->
      friend = Auth.user.friends[2]

    describe 'when the friend wasn\'t selected', ->

      beforeEach ->
        spyOn(ctrl, 'getWasSelected').and.returnValue false
        spyOn ctrl, 'selectFriend'

        ctrl.toggleSelected friend

      it 'should select the friend', ->
        expect(ctrl.selectFriend).toHaveBeenCalledWith friend


    describe 'when the friend has been selected', ->

      beforeEach ->
        spyOn(ctrl, 'getWasSelected').and.returnValue true
        ctrl.selectedFriends = [friend]
        ctrl.selectedFriendIds = {}
        ctrl.selectedFriendIds[friend.id] = true

        spyOn ctrl, 'deselectFriend'

        ctrl.toggleSelected friend

      it 'should deselect the friend', ->
        expect(ctrl.deselectFriend).toHaveBeenCalledWith friend


  describe 'toggling all nearby friends', ->

    describe 'when all nearby friends hasn\'t been selected', ->

      beforeEach ->
        ctrl.nearbyFriends = [Auth.user.friends[2], Auth.user.friends[3]]
        ctrl.selectedFriendIds = {}
        ctrl.selectedFriendIds[Auth.user.friends[3].id] = true

        spyOn ctrl, 'selectFriend'

        ctrl.toggleAllNearbyFriends()

      it 'should select the nearby friends item', ->
        expect(ctrl.isAllNearbyFriendsSelected).toBe true

      it 'should select each friend in the list of nearby friends', ->
        expect(ctrl.selectFriend).toHaveBeenCalledWith Auth.user.friends[2]


    describe 'when all nearby friends is selected', ->

      beforeEach ->
        ctrl.isAllNearbyFriendsSelected = true
        ctrl.nearbyFriends = [Auth.user.friends[2], Auth.user.friends[3]]

        spyOn ctrl, 'deselectFriend'

        ctrl.toggleAllNearbyFriends()

      it 'should deselect the nearby friends item', ->
        expect(ctrl.isAllNearbyFriendsSelected).toBe false

      it 'should deselect each friend in the list of nearby friends', ->
        for friend in ctrl.nearbyFriends
          expect(ctrl.deselectFriend).toHaveBeenCalledWith friend


  describe 'selecting a friend', ->
    friend = null

    beforeEach ->
      ctrl.selectedFriends = []
      ctrl.selectedFriendIds = {}
      spyOn(ctrl, 'getWasInvited').and.returnValue false

      friend = Auth.user.friends[2]
      ctrl.selectFriend friend

    it 'should add the friend to the array of selected friends', ->
      expect(ctrl.selectedFriends).toEqual [friend]

    it 'should add the friend to the dictionary of selected friend ids', ->
      selectedFriendIds = {}
      selectedFriendIds[friend.id] = true
      expect(ctrl.selectedFriendIds).toEqual selectedFriendIds

    it 'should check whether the friend was invited', ->
      expect(ctrl.getWasInvited).toHaveBeenCalledWith friend


  describe 'deselecting a friend', ->
    friend = null

    beforeEach ->
      friend = Auth.user.friends[2]
      ctrl.selectedFriends = [friend, Auth.user.friends[3]]
      ctrl.selectedFriendIds = {}
      ctrl.selectedFriendIds[friend.id] = true
      spyOn(ctrl, 'getWasInvited').and.returnValue false

    describe 'when the friend is a nearby friend', ->

      beforeEach ->
        ctrl.nearbyFriendIds = {}
        ctrl.nearbyFriendIds[friend.id] = true

        friendCopy = angular.copy friend
        ctrl.deselectFriend friendCopy

      it 'should remove the friend from the list of selected friends', ->
        expect(ctrl.selectedFriends).toEqual [Auth.user.friends[3]]

      it 'should remove the friend from the dictionary of selected friend ids', ->
        expect(ctrl.selectedFriendIds).toEqual {}

      it 'should check whether the friend was invited', ->
        expect(ctrl.getWasInvited).toHaveBeenCalledWith friend

      describe 'and all nearby friends is selected', ->

        beforeEach ->
          ctrl.isAllNearbyFriendsSelected = true

          friendCopy = angular.copy friend
          ctrl.deselectFriend friendCopy

        it 'should deselect all nearby friends', ->
          expect(ctrl.isAllNearbyFriendsSelected).toBe false


  describe 'sending the invitations', ->
    deferredCacheClear = null

    beforeEach ->
      ctrl.selectedFriends = [Auth.user.friends[2], Auth.user.friends[3]]
      ctrl.event = event

      deferredCacheClear = $q.defer()
      spyOn($ionicHistory, 'clearCache').and.returnValue \
          deferredCacheClear.promise

      spyOn $ionicLoading, 'show'
      spyOn $ionicLoading, 'hide'

    describe 'when inviting to an existing event', ->
      deferredBulkCreate = null

      beforeEach ->
        deferredBulkCreate = $q.defer()
        spyOn(Invitation, 'bulkCreate').and.returnValue deferredBulkCreate.promise

        # The event id is set if we're inviting people to an existing event.
        ctrl.event.id = 1

        ctrl.sendInvitations()

      it 'should show a loading spinner', ->
        template = '''
          <div class="loading-text">
            Sending...
          </div>
          <ion-spinner icon="bubbles"></ion-spinner>
          '''
        expect($ionicLoading.show).toHaveBeenCalledWith {template: template}

      it 'should bulk create invitations', ->
        invitations = ({toUserId: friend.id} \
            for friend in ctrl.selectedFriends)
        eventId = ctrl.event.id
        expect(Invitation.bulkCreate).toHaveBeenCalledWith eventId, invitations

      describe 'successfully', ->

        beforeEach ->
          spyOn ctrl, 'trackSendInvites'

          deferredBulkCreate.resolve()
          scope.$apply()

        it 'should clear the cache', ->
          expect($ionicHistory.clearCache).toHaveBeenCalled()

        it 'should track Invited friends to existing event in mixpanel', ->
          expect(ctrl.trackSendInvites).toHaveBeenCalled()

        describe 'when the cache is cleared', ->

          beforeEach ->
            spyOn $ionicHistory, 'goBack'

            deferredCacheClear.resolve()
            scope.$apply()

          it 'should go back to the event', ->
            expect($ionicHistory.goBack).toHaveBeenCalled()

          it 'should hide the loading indicator', ->
            expect($ionicLoading.hide).toHaveBeenCalled()


      describe 'unsuccessfully', ->

        beforeEach ->
          deferredBulkCreate.reject()
          scope.$apply()

        it 'should show an error', ->
          expect(ctrl.error).toBe 'inviteError'

        it 'should hide the loading indicator', ->
          expect($ionicLoading.hide).toHaveBeenCalled()


    describe 'when creating a new event', ->
      deferredEventSave = null
      newEvent = null

      beforeEach ->
        deferredEventSave = $q.defer()
        spyOn(Event, 'save').and.returnValue {$promise: deferredEventSave.promise}

        # Save the current version of the event.
        newEvent = angular.copy event

        ctrl.sendInvitations()

      it 'should show a loading spinner', ->
        expect($ionicLoading.show).toHaveBeenCalled()

      it 'should save the event', ->
        # Friend invitations
        invitations = (Invitation.serialize {toUserId: friend.id} \
            for friend in ctrl.selectedFriends)
        # The logged in user's invitation
        invitations.push Invitation.serialize
          toUserId: Auth.user.id
        newEvent.invitations = invitations
        expect(Event.save).toHaveBeenCalledWith newEvent

      describe 'successfully', ->

        beforeEach ->
          spyOn ctrl, 'trackSendInvites'
          deferredEventSave.resolve()
          scope.$apply()

        it 'should track Created an event in mixpanel', ->
          expect(ctrl.trackSendInvites).toHaveBeenCalled()

        it 'should clear the cache', ->
          expect($ionicHistory.clearCache).toHaveBeenCalled()

        describe 'when the cache is cleared', ->

          beforeEach ->
            spyOn $state, 'go'

            deferredCacheClear.resolve()
            scope.$apply()

          it 'should go to the events view', ->
            # TODO: Go to the events view before the save finishes.
            expect($state.go).toHaveBeenCalledWith 'events'

          it 'should hide the loading indicator', ->
            expect($ionicLoading.hide).toHaveBeenCalled()


      describe 'unsuccessfully', ->

        beforeEach ->
          deferredEventSave.reject()
          scope.$apply()

        it 'should show an error', ->
          expect(ctrl.error).toBe 'inviteError'

        it 'should hide the loading indicator', ->
          expect($ionicLoading.hide).toHaveBeenCalled()


  describe 'tracking send invites', ->

    beforeEach ->
      spyOn $mixpanel, 'track'
      ctrl.selectedFriends = [1, 2, 3]
      ctrl.isAllNearbyFriendsSelected = true

    describe 'when inviting to an existing event', ->

      beforeEach ->
        ctrl.event =
          id: 1

        ctrl.trackSendInvites()

      it 'should track with "existing event" property as true', ->
        expect($mixpanel.track).toHaveBeenCalledWith 'Send Invites',
          'existing event': true
          'number of invites': ctrl.selectedFriends.length
          'all nearby': ctrl.isAllNearbyFriendsSelected


    describe 'when creating an event', ->

      beforeEach ->
        ctrl.event = {}

        ctrl.trackSendInvites()

      it 'should track with "existing event" as false', ->
        expect($mixpanel.track).toHaveBeenCalledWith 'Send Invites',
          'existing event': false
          'number of invites': ctrl.selectedFriends.length
          'all nearby': ctrl.isAllNearbyFriendsSelected


  describe 'adding friends', ->

    beforeEach ->
      spyOn $state, 'go'
      ctrl.cleanupViewAfterLeave = true

      ctrl.addFriends()

    it 'should set a flag to prevent the view from being cleaned up', ->
      expect(ctrl.cleanupViewAfterLeave).toBe false

    it 'should go to the add friends view', ->
      expect($state.go).toHaveBeenCalledWith 'addFriends'


  describe 'checking whether a user was selected', ->
    friend = null
    result = null

    beforeEach ->
      friend = Auth.user.friends[2]

    describe 'when the user was selected', ->

      beforeEach ->
        ctrl.selectedFriendIds = {}
        ctrl.selectedFriendIds[friend.id] = true

        result = ctrl.getWasSelected friend

      it 'should return true', ->
        expect(result).toBe true


    describe 'when the user wasn\'t selected', ->

      beforeEach ->
        ctrl.selectedFriendIds = {}

        result = ctrl.getWasSelected friend

      it 'should return false', ->
        expect(result).toBe false


  describe 'checking whether a user was invited', ->
    friend = null
    result = null

    beforeEach ->
      friend = Auth.user.friends[2]

    describe 'when they were invited', ->

      beforeEach ->
        ctrl.invitedUserIds = {}
        ctrl.invitedUserIds[friend.id] = true

        result = ctrl.getWasInvited friend

      it 'should return true', ->
        expect(result).toBe true


    describe 'when they weren\'t invited', ->

      beforeEach ->
        ctrl.invitedUserIds = {}

        result = ctrl.getWasInvited friend

      it 'should return false', ->
        expect(result).toBe false
