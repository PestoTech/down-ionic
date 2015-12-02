require '../../ionic/ionic.js'
require 'angular'
require 'angular-mocks'
require 'angular-ui-router'
require 'ng-cordova'
require './auth-module'
require '../mixpanel/mixpanel-module'
require '../meteor/meteor-mocks'
require '../local-db/local-db-module'

describe 'Auth service', ->
  $cordovaGeolocation = null
  $cordovaDevice = null
  $httpBackend = null
  $mixpanel = null
  $meteor = null
  $rootScope = null
  scope = null
  $state = null
  $q = null
  apiRoot = null
  Auth = null
  User = null
  deserializedUser = null
  LocalDB = null
  SavedEvent = null

  beforeEach angular.mock.module('angular-meteor')

  beforeEach angular.mock.module('analytics.mixpanel')

  beforeEach angular.mock.module('rallytap.auth')

  beforeEach angular.mock.module('ngCordova.plugins.geolocation')

  beforeEach angular.mock.module('ngCordova.plugins.device')

  beforeEach angular.mock.module('ui.router')

  beforeEach angular.mock.module('rallytap.localDB')

  beforeEach angular.mock.module(($provide) ->
    $cordovaGeolocation =
      watchPosition: jasmine.createSpy '$cordovaGeolocation.watchPosition'
    $provide.value '$cordovaGeolocation', $cordovaGeolocation

    deserializedUser =
      id: 1
    class User
      constructor: (user) ->
        @id = user.id
        @name = user.name
        @authtoken = user.authtoken
        @friends = user.friends
        @facebookFriends = user.facebookFriends
      @update: jasmine.createSpy 'User.update'
      @deserialize: jasmine.createSpy('User.deserialize').and.returnValue \
          deserializedUser
      @listUrl: 'listUrl'
    $provide.value 'User', User

    $state =
      go: jasmine.createSpy '$state.go'
    $provide.value '$state', $state

    $mixpanel =
      identify: jasmine.createSpy '$mixpanel.identify'
      people:
        set: jasmine.createSpy '$mixpanel.people.set'
    $provide.value '$mixpanel', $mixpanel

    LocalDB =
      get: jasmine.createSpy 'LocalDB.get'
      set: jasmine.createSpy 'LocalDB.set'
    $provide.value 'LocalDB', LocalDB

    return
  )

  beforeEach inject(($injector) ->
    $q = $injector.get '$q'
    $httpBackend = $injector.get '$httpBackend'
    $rootScope = $injector.get '$rootScope'
    $state = $injector.get '$state'
    $meteor = $injector.get '$meteor'
    apiRoot = $injector.get 'apiRoot'
    Auth = $injector.get 'Auth'
    SavedEvent = $injector.get 'SavedEvent'
    scope = $rootScope.$new()
  )

  it 'should init the user', ->
    expect(Auth.user).toEqual {}

  it 'should init the flags', ->
    expect(Auth.flags).toEqual {}

  describe 'resume session', ->
    deferred = null
    resolved = null
    rejected = null

    beforeEach ->
      deferred = $q.defer()
      LocalDB.get.and.returnValue deferred.promise
      Auth.resumeSession()
        .then ->
          resolved = true
        , ->
          rejected = true

    it 'should get the session object from the LocalDB', ->
      expect(LocalDB.get).toHaveBeenCalledWith 'session'

    describe 'when a session is stored in local storage', ->
      user = null
      friends = null
      facebookFriends = null
      phone = null
      flags = null

      beforeEach ->
        friends =
          2:
            id: 2
            name: 'Jimbo Walker'
        facebookFriends =
          3:
            id: 3
            name: 'Other Friend'
        user =
          id: 1
          name: 'Andrew Linfoot'
          authtoken: 'asdfkasf'
          friends: friends
          facebookFriends: facebookFriends
        phone = '+19252852230'
        flags = {}

        session =
          user: user
          phone: phone
          flags: flags

        spyOn Auth, 'mixpanelIdentify'

        deferred.resolve session
        $rootScope.$apply()

      it 'should set the user on Auth', ->
        expect(Auth.user).toAngularEqual user

      it 'should log in to meteor', ->
        expect($meteor.loginWithPassword).toHaveBeenCalledWith("#{user.id}",
            user.authtoken)

      it 'should identify the user with mixpanel', ->
        expect(Auth.mixpanelIdentify).toHaveBeenCalled()

      it 'should set the phone on Auth', ->
        expect(Auth.phone).toEqual phone

      it 'should set the flags on Auth', ->
        expect(Auth.flags).toBe flags

      describe 'when a user has friends', ->

        it 'should set the friends on the user', ->
          expect(Auth.user.friends).toAngularEqual friends


      describe 'when a user has facebook friends', ->

        it 'should set the facebookFriends on the user', ->
          expect(Auth.user.facebookFriends).toAngularEqual facebookFriends

      it 'should resolve the promise', ->
        expect(resolved).toBe true


    describe 'when there is a LocalDB error', ->

      beforeEach ->
        deferred.reject()
        $rootScope.$apply()

      it 'should reject the promise', ->
        expect(rejected).toBe true


  describe 'saving the session', ->
    user = null
    phone = null
    flags = null
    deferred = null
    rejected = null
    resolved = null

    beforeEach ->
      user =
          id: 1
          name: 'Andrew Linfoot'
          authtoken: 'asdfkasf'
      phone = '+19252852230'
      flags = {}

      Auth.user = user
      Auth.phone = phone
      Auth.flags = flags

      deferred = $q.defer()
      LocalDB.set.and.returnValue deferred.promise

      Auth.saveSession()
        .then ->
          resolved = true
        , ->
          rejected = true

    it 'should save the session to LocalDB', ->
      expect(LocalDB.set).toHaveBeenCalledWith 'session',
        user: user
        phone: phone
        flags: flags

    describe 'saved successfully', ->

      beforeEach ->
        deferred.resolve()
        $rootScope.$apply()

      it 'should resolve the promise', ->
        expect(resolved).toBe true


    describe 'save fails', ->

      beforeEach ->
        deferred.reject()
        $rootScope.$apply()

      it 'should reject the promise', ->
        expect(rejected).toBe true


  describe 'mixpanel identify', ->

    beforeEach ->
      Auth.user =
        id: 1
      Auth.mixpanelIdentify()

    it 'should identify the user with mixpanel', ->
      expect($mixpanel.identify).toHaveBeenCalledWith Auth.user.id


    describe 'when a user has a name', ->
      name = null

      beforeEach ->
        name = 'Jimbo'
        Auth.user =
          id: 1
          name: name
        Auth.mixpanelIdentify()

      it 'should send the name to mixpanel', ->
        expect($mixpanel.people.set).toHaveBeenCalledWith {$name: name}


    describe 'when a user has an email', ->
      email = null

      beforeEach ->
        email = 'ajlin500@gmail.com'
        Auth.user =
          id: 1
          email: email
        Auth.mixpanelIdentify()

      it 'should send the email to mixpanel', ->
        expect($mixpanel.people.set).toHaveBeenCalledWith {$email: email}


    describe 'when a user has a username', ->
      username = null

      beforeEach ->
        username = 'a'
        Auth.user =
          id: 1
          username: username
        Auth.mixpanelIdentify()

      it 'should send the username to mixpanel', ->
        expect($mixpanel.people.set).toHaveBeenCalledWith {$username: username}


  describe 'set user', ->
    user = null
    expectedUser = null
    saveSession = null
    result = null

    beforeEach ->
      Auth.user =
        facebookFriends:
          2:
            id: 2
          3:
            id: 3
      user =
        id: 1
      expectedUser = angular.extend({}, Auth.user, user)

      spyOn Auth, 'mixpanelIdentify'
      saveSession = 'saveSession'
      spyOn(Auth, 'saveSession').and.returnValue saveSession

      result = Auth.setUser user

    it 'should extend passed in user with auth.user', ->
      expect(Auth.user).toEqual expectedUser

    it 'should identify the user in mixpanel', ->
      expect(Auth.mixpanelIdentify).toHaveBeenCalled()

    it 'should return the save session promise', ->
      expect(result).toBe saveSession

  ##setPhone
  describe 'set phone', ->
    phone = null
    result = null
    saveSession = null

    beforeEach ->
      Auth.phone = null
      phone = '19252852230'
      saveSession = 'saveSession'
      spyOn(Auth, 'saveSession').and.returnValue saveSession

      result = Auth.setPhone phone

    it 'should set Auth.phone', ->
      expect(Auth.phone).toEqual phone

    it 'should return the save session promise', ->
      expect(result).toBe saveSession


  ##setFlag
  describe 'setting a flag', ->
    flagKey = null
    flagValue = null
    saveSession = null
    result = null

    beforeEach ->
      flagKey = 'hasRequestedPushNotifications'
      flagValue = true
      Auth.flags = {}

      saveSession = 'saveSession'
      spyOn(Auth, 'saveSession').and.returnValue saveSession

      result = Auth.setFlag flagKey, flagValue

    it 'should set the flag on Auth', ->
      expect(Auth.flags[flagKey]).toBe flagValue

    it 'should return the save session promise', ->
      expect(result).toBe saveSession


  ##isAuthenticated
  describe 'checking whether the user is authenticated', ->
    testAuthUrl = null

    beforeEach ->
      testAuthUrl = "#{apiRoot}/users/me"

    describe 'when the user is authenticated', ->

      it 'should return true', ->
        $httpBackend.expectGET testAuthUrl
          .respond 200, null

        result = null
        Auth.isAuthenticated()
          .then (_result_) ->
            result = _result_
        $httpBackend.flush 1

        expect(result).toBe true


    describe 'when the user is not authenticated', ->

      it 'should return false', ->
        $httpBackend.expectGET testAuthUrl
          .respond 401, null

        result = null
        Auth.isAuthenticated()
          .then (_result_) ->
            result = _result_
        $httpBackend.flush 1

        expect(result).toBe false


    describe 'when the request fails', ->

      it 'should reject the promise', ->
        $httpBackend.expectGET testAuthUrl
          .respond 500, null

        rejected = false
        Auth.isAuthenticated()
          .then null, ->
            rejected = true
        $httpBackend.flush 1

        expect(rejected).toBe true


  ##getMe
  describe 'getting the logged in user', ->
    meUrl = null

    beforeEach ->
      meUrl = "#{apiRoot}/users/me"

    describe 'when the user is authenticated', ->
      user = null

      it 'should return the user', ->
        user = id: 1
        $httpBackend.expectGET meUrl
          .respond 200, user

        result = null
        Auth.getMe()
          .then (_result_) ->
            result = _result_
        $httpBackend.flush 1

        expect(result).toBe deserializedUser


    describe 'when the user is not authenticated', ->
      rejected = null

      it 'should reject the promise', ->
        $httpBackend.expectGET meUrl
          .respond 401, null

        rejected = false
        Auth.getMe()
          .then null, ->
            rejected = true
        $httpBackend.flush 1

        expect(rejected).toBe true


    describe 'when the request fails', ->

      it 'should reject the promise', ->
        $httpBackend.expectGET meUrl
          .respond 500, null

        rejected = false
        Auth.getMe()
          .then null, ->
            rejected = true
        $httpBackend.flush 1

        expect(rejected).toBe true


  describe 'authenticating', ->
    authenticateUrl = null
    code = null
    phone = null
    postData = null

    beforeEach ->
      authenticateUrl = "#{apiRoot}/sessions"
      phone = '+1234567890'
      code = 'asdf1234'
      postData =
        phone: phone
        code: code

    describe 'when the request succeeds', ->
      responseData = null
      response = null

      beforeEach ->
        friend =
          id: 2
          email: 'jclarke@gmail.com'
          name: 'Joan Clarke'
          username: 'jmamba'
          image_url: 'http://imgur.com/jcke'
          location:
            type: 'Point'
            coordinates: [40.7265836, -73.9821539]
        responseData =
          id: 1
          email: 'aturing@gmail.com'
          name: 'Alan Turing'
          username: 'tdog'
          image_url: 'https://facebook.com/profile-pic/tdog'
          location:
            type: 'Point'
            coordinates: [40.7265834, -73.9821535]
          authtoken: 'fdsa4321'
          friends: [friend]
          facebook_friends: [friend]
        $httpBackend.expectPOST authenticateUrl, postData
          .respond 200, responseData

        Auth.authenticate(phone, code)
          .then (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should call deserialize with response data', ->
        expect(User.deserialize).toHaveBeenCalledWith responseData
        expect(User.deserialize.calls.count()).toBe 1

      it 'should get or create the user', ->
        expect(response).toAngularEqual deserializedUser

      it 'should set the returned user on the Auth object', ->
        expect(Auth.user).toEqual deserializedUser


    describe 'when the request fails', ->

      it 'should reject the promise', ->
        status = 500
        $httpBackend.expectPOST authenticateUrl, postData
          .respond status, null

        rejectedStatus = null
        Auth.authenticate phone, code
          .then null, (_status_) ->
            rejectedStatus = _status_
        $httpBackend.flush 1

        expect(rejectedStatus).toEqual status


  describe 'logging in with facebook', ->
    fbAuthUrl = null
    accessToken = null
    postData = null

    beforeEach ->
      fbAuthUrl = "#{apiRoot}/sessions/facebook"
      accessToken = 'mikeisstinky'
      postData = access_token: accessToken

    describe 'on success', ->
      responseData = null
      response = null

      beforeEach ->
        friend =
          id: 2
          email: 'jclarke@gmail.com'
          name: 'Joan Clarke'
          username: 'jmamba'
          image_url: 'http://imgur.com/jcke'
          location:
            type: 'Point'
            coordinates: [40.7265836, -73.9821539]
        responseData =
          id: 1
          email: 'aturing@gmail.com'
          name: 'Alan Turing'
          username: 'tdog'
          image_url: 'https://facebook.com/profile-pic/tdog'
          location:
            type: 'Point'
            coordinates: [40.7265834, -73.9821535]
          authtoken: 'fdsa4321'
          facebook_friends: [friend]
        $httpBackend.expectPOST fbAuthUrl, postData
          .respond 200, responseData

        Auth.facebookLogin accessToken
          .then (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should call deserialize with response data', ->
        expect(User.deserialize).toHaveBeenCalledWith responseData
        expect(User.deserialize.calls.count()).toBe 1

      it 'should get or create the user', ->
        expect(response).toAngularEqual deserializedUser


    describe 'when the request fails', ->

      it 'should reject the promise', ->
        status = 500
        $httpBackend.expectPOST fbAuthUrl, postData
          .respond status, null

        rejectedStatus = null
        Auth.facebookLogin accessToken
          .then null, (_status_) ->
            rejectedStatus = _status_
        $httpBackend.flush 1

        expect(rejectedStatus).toEqual status


  describe 'syncing with facebook', ->
    fbSyncUrl = null
    accessToken = null
    postData = null

    beforeEach ->
      fbSyncUrl = "#{apiRoot}/social-account"
      accessToken = 'poiu0987'
      postData = access_token: accessToken

    describe 'on success', ->
      friend = null
      responseData = null
      response = null

      beforeEach ->
        spyOn Auth, 'setUser'

        Auth.user =
          id: 1
          location:
            lat: 40.7265834
            long: -73.9821535
          authtoken: 'fdsa4321'
        friend =
          id: 2
          email: 'jclarke@gmail.com'
          name: 'Joan Clarke'
          username: 'jnasty'
          image_url: 'https://facebook.com/profile-pics/jnasty'
        responseData =
          id: Auth.user.id
          email: 'aturing@gmail.com'
          name: 'Alan Turing'
          image_url: 'https://facebook.com/profile-pic/tdog'
          location:
            type: 'Point'
            coordinates: [Auth.user.location.lat, Auth.user.location.long]
          facebook_friends: [friend]
        $httpBackend.expectPOST fbSyncUrl, postData
          .respond 201, responseData

        facebookFriends = {}
        facebookFriends[friend.id] = friend
        deserializedUser =
          id: responseData.id
          email: responseData.email
          name: responseData.name
          imageUrl: responseData.image_url
          location:
            lat: responseData.location.coordinates[0]
            long: responseData.location.coordinates[1]
          facebookFriends: facebookFriends
        User.deserialize.and.returnValue deserializedUser

        Auth.facebookSync accessToken
          .then (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should return the user', ->
        expect(response).toAngularEqual Auth.user

      it 'should save the user in local storage', ->
        expect(Auth.setUser).toHaveBeenCalledWith deserializedUser


    describe 'on error', ->

      it 'should reject the promise', ->
        status = 500
        $httpBackend.expectPOST fbSyncUrl, postData
          .respond status, null

        rejectedStatus = null
        Auth.facebookSync accessToken
          .then null, (_status_) ->
            rejectedStatus = _status_
        $httpBackend.flush 1

        expect(rejectedStatus).toBe status


  describe 'sending a verification text', ->
    verifyPhoneUrl = null
    phone = null
    postData = null

    beforeEach ->
      verifyPhoneUrl = "#{apiRoot}/authcodes"
      phone = '+1234567890'
      postData = {phone: phone}

    describe 'on success', ->
      response = null

      beforeEach ->
        $httpBackend.expectPOST verifyPhoneUrl, postData
          .respond 200, null

        Auth.sendVerificationText phone
          .then null, (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should set Auth.phone', ->
        expect(Auth.phone).toBe phone

    describe 'on error', ->

      it 'should reject the promise', ->
        $httpBackend.expectPOST verifyPhoneUrl, postData
          .respond 500, null

        rejected = false
        Auth.sendVerificationText phone
          .then null, ->
            rejected = true
        $httpBackend.flush 1

        expect(rejected).toBe true


  describe 'checking whether a user is a friend', ->
    user = null

    beforeEach ->
      Auth.user.friends = {}
      user =
        id: 1

    describe 'when the user is a friend', ->

      beforeEach ->
        Auth.user.friends[user.id] = user

      it 'should return true', ->
        expect(Auth.isFriend user.id).toBe true


    describe 'when the user isn\'t a friend', ->

      it 'should return true', ->
        expect(Auth.isFriend user.id).toBe false


  describe 'redirecting for auth state', ->

    describe 'when you haven\'t viewed the tutorial yet', ->

      beforeEach ->
        Auth.redirectForAuthState()

      it 'should send the user to the tutorial view', ->
        expect($state.go).toHaveBeenCalledWith 'tutorial'


    describe 'no phone number entered', ->

      beforeEach ->
        Auth.flags.hasViewedTutorial = true
        Auth.phone = undefined
        Auth.redirectForAuthState()

      it 'should send the user to the enter phone view', ->
        expect($state.go).toHaveBeenCalledWith 'login'


    describe 'no authenticated user', ->

      beforeEach ->
        Auth.flags.hasViewedTutorial = true
        Auth.phone = '+19252852230'
        Auth.user = {}
        Auth.redirectForAuthState()

      it 'should send the user to the enter verification code view', ->
        expect($state.go).toHaveBeenCalledWith 'verifyPhone'


    describe 'the user doesn\'t have an image url', ->

      beforeEach ->
        Auth.flags.hasViewedTutorial = true
        Auth.phone = '+19252852230'
        Auth.user =
          id: 1
        Auth.redirectForAuthState()

      it 'should send the user to the sync with facebook view', ->
        expect($state.go).toHaveBeenCalledWith 'facebookSync'


    describe 'the user doesn\'t have a username', ->

      beforeEach ->
        Auth.flags.hasViewedTutorial = true
        Auth.phone = '+19252852230'
        Auth.user =
          id: 1
          name: 'Alan Turing'
          email: 'aturing@gmail.com'
          imageUrl: 'https://facebook.com/profile-pic/tdog'
        Auth.redirectForAuthState()

      it 'should go to the add username view', ->
        expect($state.go).toHaveBeenCalledWith 'setUsername'

    describe 'when using an iOS device', ->

      beforeEach ->
        Auth.flags.hasViewedTutorial = true
        spyOn(ionic.Platform, 'isIOS').and.returnValue true

      describe 'we haven\'t requested location services', ->

        beforeEach ->
          Auth.phone = '+19252852230'
          Auth.user =
            id: 1
            name: 'Alan Turing'
            email: 'aturing@gmail.com'
            imageUrl: 'https://facebook.com/profile-pic/tdog'
            username: 'tdog'
          Auth.redirectForAuthState()

        it 'should go to the request push notifications view', ->
          expect($state.go).toHaveBeenCalledWith 'requestLocation'


      describe 'we haven\'t requested push services', ->

        beforeEach ->
          Auth.phone = '+19252852230'
          Auth.user =
            id: 1
            name: 'Alan Turing'
            email: 'aturing@gmail.com'
            imageUrl: 'https://facebook.com/profile-pic/tdog'
            location:
              lat: 40.7265834
              long: -73.9821535
            username: 'tdog'
          Auth.flags.hasRequestedLocationServices = true
          Auth.redirectForAuthState()

        it 'should go to the request push notifications view', ->
          expect($state.go).toHaveBeenCalledWith 'requestPush'

      describe 'we haven\'t requested contacts access', ->

        beforeEach ->
          Auth.phone = '+19252852230'
          Auth.user =
            id: 1
            name: 'Alan Turing'
            email: 'aturing@gmail.com'
            imageUrl: 'https://facebook.com/profile-pic/tdog'
            location:
              lat: 40.7265834
              long: -73.9821535
            username: 'tdog'
          Auth.flags.hasRequestedLocationServices = true
          Auth.flags.hasRequestedPushNotifications = true
          Auth.redirectForAuthState()

        it 'should go to the request contacts view', ->
          expect($state.go).toHaveBeenCalledWith 'requestContacts'

    describe 'we haven\'t shown the find friends view', ->

      beforeEach ->
        Auth.flags.hasViewedTutorial = true
        spyOn(ionic.Platform, 'isIOS').and.returnValue true
        spyOn(ionic.Platform, 'isAndroid').and.returnValue true

        Auth.phone = '+19252852230'
        Auth.user =
          id: 1
          name: 'Alan Turing'
          email: 'aturing@gmail.com'
          imageUrl: 'https://facebook.com/profile-pic/tdog'
          location:
            lat: 40.7265834
            long: -73.9821535
          username: 'tdog'
        Auth.flags.hasRequestedLocationServices = true
        Auth.flags.hasRequestedPushNotifications = true
        Auth.flags.hasRequestedContacts = true
        Auth.redirectForAuthState()

      it 'should go to the find friends view', ->
        expect($state.go).toHaveBeenCalledWith 'findFriends'


    describe 'user has already completed sign up', ->

      beforeEach ->
        Auth.flags.hasViewedTutorial = true
        Auth.phone = '+19252852230'
        Auth.user =
          id: 1
          name: 'Alan Turing'
          email: 'aturing@gmail.com'
          imageUrl: 'https://facebook.com/profile-pic/tdog'
          location:
            lat: 40.7265834
            long: -73.9821535
          username: 'tdog'
        Auth.flags.hasRequestedLocationServices = true
        Auth.flags.hasRequestedPushNotifications = true
        Auth.flags.hasRequestedContacts = true
        Auth.flags.hasCompletedFindFriends = true
        Auth.redirectForAuthState()

      it 'should go to the events view', ->
        expect($state.go).toHaveBeenCalledWith 'events'


  describe 'watching the users location', ->
    cordovaDeferred = null
    promise = null

    beforeEach ->
      cordovaDeferred = $q.defer()
      $cordovaGeolocation.watchPosition.and.returnValue cordovaDeferred.promise

      spyOn Auth, 'updateLocation'

      promise = Auth.watchLocation()

    it 'should periodically ask the device for the users location', ->
      expect($cordovaGeolocation.watchPosition).toHaveBeenCalled()

    describe 'when location data is received sucessfully', ->
      user = null
      location = null
      resolved = null

      beforeEach ->
        lat = 180.0
        long = 180.0
        location =
          lat: lat
          long: long
        position =
          coords:
            latitude: lat
            longitude: long

        resolved = false
        promise.then ->
          resolved = true

        cordovaDeferred.notify position
        scope.$apply()

      it 'should call update location with the location data', ->
        expect(Auth.updateLocation).toHaveBeenCalledWith location

      it 'should resolve the promise', ->
        expect(resolved).toBe true


    describe 'when location data cannot be recieved', ->
      rejected = null

      describe 'when using an iOS device', ->

        beforeEach ->
          spyOn(ionic.Platform, 'isIOS').and.returnValue true

        describe 'because location permissions are denied', ->
          beforeEach ->
            error =
              code: 1

            rejected = false
            promise.then null, ->
              rejected = true

            cordovaDeferred.reject error
            scope.$apply()

          it 'should send the user to the enable location services view', ->
            expect($state.go).toHaveBeenCalledWith 'requestLocation'

          it 'should reject the promise', ->
            expect(rejected).toBe true


      describe 'because of timeout or location unavailable', ->
        resolved = null

        beforeEach ->
          resolved = false
          promise.then ->
            resolved = true

          error =
            code: 'PositionError.POSITION_UNAVAILABLE'

          cordovaDeferred.reject error
          scope.$apply()

        it 'should resolve the promise', ->
          expect(resolved).toBe true


  describe 'update the users location', ->
    deferred = null
    user = null

    beforeEach ->
      lat = 180.0
      long = 180.0

      location =
        lat: 180.0
        long: 180.0

      user = angular.copy Auth.user
      user.location = location

      deferred = $q.defer()
      User.update.and.returnValue {$promise: deferred.promise}

      Auth.updateLocation location

    it 'should save the user with the location data', ->
      expect(User.update).toHaveBeenCalledWith user

      describe 'when successful', ->

        beforeEach ->
          spyOn Auth, 'setUser'

          deferred.resolve user
          scope.$apply()

        it 'should update the Auth.user', ->
          expect(Auth.setUser).toHaveBeenCalledWith user


  describe 'checking whether a friend is nearby', ->
    user = null

    beforeEach ->
      Auth.user.location =
        lat: 40.7265834
        long: -73.9821535
      user =
        id: 2
        email: 'jclarke@gmail.com'
        name: 'Joan Clarke'
        username: 'jnasty'
        imageUrl: 'https://facebook.com/profile-pics/jnasty'

    describe 'when the user doesn\'t have a location', ->

      it 'should return false', ->
        expect(Auth.isNearby user).toBe false


    describe 'when the authenticated user doesn\'t have a location', ->

      beforeEach ->
        user.location =
          lat: 40.7265834
          long: -73.9821535
        Auth.user.location = undefined

      it 'should return false', ->
        expect(Auth.isNearby user).toBe false


    describe 'when the user is at most 5 mi away', ->

      beforeEach ->
        user.location =
          lat: 40.7265834 # just under 5 mi away
          long: -73.9821535

      it 'should return true', ->
        expect(Auth.isNearby user).toBe true


    describe 'when the user is more than 5 mi away', ->

      beforeEach ->
        user.location =
          lat: 40.79893 # just over 5 mi away
          long: -73.9821535

      it 'should return false', ->
        expect(Auth.isNearby user).toBe false


  ##getFriends
  describe 'querying the user\'s friends', ->
    url = null

    beforeEach ->
      url = "#{User.listUrl}/friends"

    describe 'successfully', ->
      response = null
      responseData = null

      beforeEach ->
        spyOn Auth, 'setUser'
        responseData = [
          id: 1
          email: 'aturing@gmail.com'
          name: 'Alan Turing'
          username: 'tdog'
          image_url: 'https://facebook.com/profile-pic/tdog'
          location:
            type: 'Point'
            coordinates: [40.7265834, -73.9821535]
        ]

        $httpBackend.expectGET url
          .respond 200, angular.toJson(responseData)

        response = null
        Auth.getFriends()
          .$promise.then (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should GET the users', ->
        friend = User.deserialize responseData[0]
        friends = {}
        friends[friend.id] = friend
        expect(response).toAngularEqual friends

      it 'should save the friends on the user', ->
        user = angular.copy Auth.user
        friend = User.deserialize responseData[0]
        user.friends = {}
        user.friends[friend.id] = friend
        expect(Auth.setUser).toHaveBeenCalledWith user


    describe 'with a random error', ->
      rejected = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 500, ''

        rejected = false
        Auth.getFriends()
          .$promise.then null, ->
            rejected = true
        $httpBackend.flush 1

      it 'should reject the promise', ->
        expect(rejected).toBe true


  ##getFacebookFriends
  describe 'querying the user\'s facebook friends', ->
    url = null

    beforeEach ->
      url = "#{User.listUrl}/facebook-friends"

    describe 'successfully', ->
      response = null
      responseData = null

      beforeEach ->
        spyOn Auth, 'setUser'
        responseData = [
          id: 1
          email: 'aturing@gmail.com'
          name: 'Alan Turing'
          username: 'tdog'
          image_url: 'https://facebook.com/profile-pic/tdog'
          location:
            type: 'Point'
            coordinates: [40.7265834, -73.9821535]
        ]

        $httpBackend.expectGET url
          .respond 200, angular.toJson(responseData)

        response = null
        Auth.getFacebookFriends()
          .$promise.then (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should GET the users', ->
        friend = User.deserialize responseData[0]
        facebookFriends = {}
        facebookFriends[friend.id] = friend
        expect(response).toAngularEqual facebookFriends

      it 'should save the friends on the user', ->
        user = angular.copy Auth.user
        friend = User.deserialize responseData[0]
        user.facebookFriends = {}
        user.facebookFriends[friend.id] = friend
        expect(Auth.setUser).toHaveBeenCalledWith user


    describe 'with a random error', ->
      rejected = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 500, ''

        rejected = false
        Auth.getFacebookFriends()
          .$promise.then null, ->
            rejected = true
        $httpBackend.flush 1

      it 'should reject the promise', ->
        expect(rejected).toBe true


    describe 'with a missing social account error', ->
      error = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 400, ''

        Auth.getFacebookFriends()
          .$promise.then null, (_error_) ->
            error = _error_
        $httpBackend.flush 1

      it 'should reject the promise', ->
        expect(error).toBe 'MISSING_SOCIAL_ACCOUNT'


  ##getAddedMe
  describe 'querying the users who added the current user', ->
    url = null

    beforeEach ->
      url = "#{User.listUrl}/added-me"

    describe 'successfully', ->
      response = null
      responseData = null

      beforeEach ->
        responseData = [
          id: 1
          email: 'aturing@gmail.com'
          name: 'Alan Turing'
          username: 'tdog'
          image_url: 'https://facebook.com/profile-pic/tdog'
          location:
            type: 'Point'
            coordinates: [40.7265834, -73.9821535]
        ]

        $httpBackend.expectGET url
          .respond 200, angular.toJson(responseData)

        response = null
        Auth.getAddedMe()
          .$promise.then (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should GET the users', ->
        friend = User.deserialize responseData[0]
        expect(response).toAngularEqual [friend]


    describe 'with a random error', ->
      rejected = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 500, ''

        rejected = false
        Auth.getAddedMe()
          .$promise.then null, ->
            rejected = true
        $httpBackend.flush 1

      it 'should reject the promise', ->
        expect(rejected).toBe true


  ##getDistanceAway
  describe 'getting how far away a location is', ->
    user = null
    distanceAway = null

    beforeEach ->
      Auth.user.location =
        lat: 40.7138251
        long: -73.9897481


    describe 'when it\'s < 500 ft away', ->

      beforeEach ->
        location =
          lat: 40.7151
          long: -73.9897481

        distanceAway = Auth.getDistanceAway location

      it 'should show the distance away', ->
        expect(distanceAway).toBe '500 feet'


    describe 'when it\'s 500 ft to 1.5 miles away', ->

      beforeEach ->
        location =
          lat: 40.7281
          long: -73.9897481

        distanceAway = Auth.getDistanceAway location

      it 'should show the distance away', ->
        expect(distanceAway).toBe '1 mile'


    describe 'when it\'s 1 mile to 100 miles away', ->

      beforeEach ->
        location =
          lat: 40.78
          long: -73.9897481

        distanceAway = Auth.getDistanceAway location

      it 'should show the distance away', ->
        expect(distanceAway).toBe '5 miles'


    describe 'when it\'s > 100 miles away', ->

      beforeEach ->
        location =
          lat: 42.2
          long: -73.9897481

        distanceAway = Auth.getDistanceAway location

      it 'should show the distance away', ->
        expect(distanceAway).toBe 'really far'


    describe 'when user\'s location isn\'t set', ->

      beforeEach ->
        location =
          lat: 40.7151
          long: -73.9897481
        delete Auth.user.location

        distanceAway = Auth.getDistanceAway location

      it 'should default to really far', ->
        expect(distanceAway).toBeNull()


    describe 'when no location is passed in', ->

      beforeEach ->
        location = undefined
        distanceAway = Auth.getDistanceAway location

      it 'should default to really far', ->
        expect(distanceAway).toBeNull()


  describe 'getting team rallytap', ->
    url = null
    teamrallytap = null

    beforeEach ->
      url = "#{apiRoot}/sessions/teamrallytap"
      teamrallytap =
        id: 1

    describe 'successfully', ->
      result = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 200, angular.copy(teamrallytap)

        Auth.getTeamRallytap()
          .$promise.then (_result_) ->
            result = _result_
        $httpBackend.flush 1

      it 'should GET the user', ->
        expect(result).toEqual User.deserialize(teamrallytap)


    describe 'unsuccessfully', ->
      rejected = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 403, null

        rejected = false
        Auth.getTeamRallytap()
          .$promise.then null, ->
            rejected = true
        $httpBackend.flush 1

      it 'should reject the promise', ->
        expect(rejected).toBe true


  ##getSavedEvents
  describe 'getting the current users saved events', ->
    url = null

    beforeEach ->
      url = "#{User.listUrl}/saved-events"

    describe 'successfully', ->
      response = null
      responseData = null

      beforeEach ->
        responseData = [
          id: 1
          event: 2
          user: 3
        ]

        $httpBackend.expectGET url
          .respond 200, angular.toJson(responseData)

        response = null
        Auth.getSavedEvents()
          .$promise.then (_response_) ->
            response = _response_
        $httpBackend.flush 1

      it 'should GET the saved events', ->
        savedEvent = SavedEvent.deserialize responseData[0]
        expect(response).toAngularEqual [savedEvent]


    describe 'on error', ->
      rejected = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 500, ''

        rejected = false
        Auth.getSavedEvents()
          .$promise.then null, ->
            rejected = true
        $httpBackend.flush 1

      it 'should reject the promise', ->
        expect(rejected).toBe true


  ##addPoints
  describe 'adding points', ->

    beforeEach ->
      spyOn Auth, 'saveSession'
      Auth.user.points = 1
      Auth.addPoints 1

    it 'should add the points', ->
      expect(Auth.user.points).toEqual 2

    it 'should save the session', ->
      expect(Auth.saveSession).toHaveBeenCalled()
