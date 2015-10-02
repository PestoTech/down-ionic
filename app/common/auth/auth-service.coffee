haversine = require 'haversine'
require '../../ionic/ionic.js'

class Auth
  @$inject: ['$http', '$q', '$meteor', '$mixpanel', 'apiRoot', 'User',
             '$cordovaGeolocation', '$state', 'localStorageService']
  constructor: (@$http, @$q, @$meteor, @$mixpanel, @apiRoot, @User,
                @$cordovaGeolocation, @$state, localStorageService) ->
    @localStorage = localStorageService

  user: {}

  resumeSession: ->
    # Check local storage for currentUser
    currentUser = @localStorage.get 'currentUser'
    if currentUser isnt null
      @user = new @User currentUser

      # Set friends as instances of User resource
      if @user.friends isnt undefined
        for id, friend of @user.friends
          @user.friends[id] = new @User friend
      if @user.facebookFriends isnt undefined
        for id, friend of @user.facebookFriends
          @user.facebookFriends[id] = new @User friend

      # re-establish Meteor auth
      @$meteor.loginWithPassword "#{@user.id}", @user.authtoken

      @mixpanelIdentify()

    # Check local storage for currentPhone
    currentPhone = @localStorage.get 'currentPhone'
    if currentPhone isnt null
      @phone = currentPhone

  mixpanelIdentify: ->
    #identify and set user data with mixpanel
    @$mixpanel.identify @user.id
    if @user.name isnt undefined
      @$mixpanel.people.set {$name: @user.name}
    if @user.email isnt undefined
      @$mixpanel.people.set {$email: @user.email}
    if @user.username isnt undefined
      @$mixpanel.people.set {$username: @user.username}

  setUser: (user) ->
    @user = angular.extend @user, user
    @localStorage.set 'currentUser', @user
    @mixpanelIdentify()

  setPhone: (phone) ->
    @phone = phone
    @localStorage.set 'currentPhone', @phone

  isAuthenticated: ->
    deferred = @$q.defer()

    @$http.get "#{@apiRoot}/users/me"
      .success (data, status) ->
        deferred.resolve true
      .error (data, status) ->
        if status is 401
          deferred.resolve false
        else
          deferred.reject()

    deferred.promise

  ###*
   * Check verification code with the server
   *
   * @param  {String} phone
   * @param  {String} code
   * @return {Promise}
  ###
  authenticate: (phone, code) ->
    deferred = @$q.defer()

    params =
      phone: phone
      code: code
    @$http.post "#{@apiRoot}/sessions", params
      .success (data, status) =>
        @user = @User.deserialize data
        deferred.resolve @user
      .error (data, status) ->
        deferred.reject status

    deferred.promise

  facebookLogin: (accessToken) ->
    deferred = @$q.defer()

    @$http.post "#{@apiRoot}/sessions/facebook", {access_token: accessToken}
      .success (data, status) =>
        @user = @User.deserialize data
        deferred.resolve @user
      .error (data, status) ->
        deferred.reject status

    deferred.promise

  facebookSync: (accessToken) ->
    deferred = @$q.defer()

    @$http.post "#{@apiRoot}/social-account", {access_token: accessToken}
      .success (data, status) =>
        user = @User.deserialize data
        @setUser user
        deferred.resolve @user
      .error (data, status) ->
        deferred.reject status

    deferred.promise

  sendVerificationText: (phone) ->
    @$http.post "#{@apiRoot}/authcodes", {phone: phone}
      .success (data, status) =>
        @phone = phone

  isFriend: (userId) ->
    if @user.friends[userId]?
      return true
    else
      return false

  isNearby: (user) ->
    if user.location is undefined or @user.location is undefined
      return false

    start =
      latitude: @user.location.lat
      longitude: @user.location.long
    end =
      latitude: user.location.lat
      longitude: user.location.long
    haversine(start, end, {unit: 'mile'}) <= 5

  redirectForAuthState: ->
    isIOS = ionic.Platform.isIOS()

    if not @phone?
      @$state.go 'login'
    else if not @user?.id
      @$state.go 'verifyPhone'
    else if not @user.imageUrl?
      @$state.go 'facebookSync'
    else if not @user.username?
      @$state.go 'setUsername'
    else if @localStorage.get('hasRequestedLocationServices') is null \
         and isIOS
      @$state.go 'requestLocation'
    else if @localStorage.get('hasRequestedPushNotifications') is null \
         and isIOS
      @$state.go 'requestPush'
    else if @localStorage.get('hasRequestedContacts') is null \
         and isIOS
      @$state.go 'requestContacts'
    else if @localStorage.get('hasCompletedFindFriends') is null
      @$state.go 'findFriends'
    else
      @$state.go 'events'

  watchLocation: ->
    deferred = @$q.defer()

    @$cordovaGeolocation.watchPosition()
      .then null, (error) =>
        if error.code is 1 and ionic.Platform.isIOS()
          @$state.go 'requestLocation'
          deferred.reject()
        else
          deferred.resolve()
      , (position) =>
        deferred.resolve()

        location =
          lat: position.coords.latitude
          long: position.coords.longitude
        @updateLocation location

    deferred.promise

  updateLocation: (location) ->
    user = angular.copy @user
    user.location = location
    @User.update(user).$promise.then (user) =>
      @setUser user

  getFacebookFriends: ->
    deferred = @$q.defer()

    @$http.get "#{@User.listUrl}/facebook-friends"
      .success (data, status) =>
        facebookFriendsArray = (@User.deserialize(user) for user in data)
        @user.facebookFriends = {}
        for friend in facebookFriendsArray
          @user.facebookFriends[friend.id] = friend
        @setUser @user
        deferred.resolve @user.facebookFriends
      .error (data, status) =>
        if status is 400
          deferred.reject 'MISSING_SOCIAL_ACCOUNT'
        deferred.reject()

    {$promise: deferred.promise}

  getAddedMe: ->
    deferred = @$q.defer()

    @$http.get "#{@User.listUrl}/added-me"
      .success (data, status) =>
        deferred.resolve (@User.deserialize(user) for user in data)
      .error (data, status) =>
        deferred.reject()

    {$promise: deferred.promise}

module.exports = Auth
