class InviteFriendsCtrl
  constructor: (@$ionicHistory, @$ionicLoading, @$scope, @$state, @Auth, @Event,
                @Invitation) ->
    @selectedFriends = []
    @selectedFriendIds = {}
    @invitedUserIds = {}

    @$scope.$on '$ionicView.enter', =>
      # use existing event if not set on state params
      #   i.e. coming back from add friends
      # NOTE : use @$state.params instead of @$stateParams
      #   because https://github.com/driftyco/ionic/issues/3884
      @event = @$state.params.event or @event
      # Clear previous errors
      @error = false

      # Default to calling cleanupView after leaving
      #   addFriends overwrites this
      @cleanupViewAfterLeave = true

      # Don't animate the transition to the next view.
      @$ionicHistory.nextViewOptions
        disableAnimate: true

      if 'id' of @event
        # We're inviting more people to an existing event.
        @$ionicLoading.show
          template: '''
            <ion-spinner icon="bubbles"></ion-spinner>
          '''
        @Event.getInvitedIds(@event)
          .then (invitedUserIds) =>
            for id in invitedUserIds
              @invitedUserIds[id] = true
            @buildItems()
          , =>
            @error = 'getInvitedIdsError'
          .finally =>
            @$ionicLoading.hide()
      else
        # We're creating a new event.
        @buildItems()

    @$scope.$on '$ionicView.afterLeave', =>
      if @cleanupViewAfterLeave
        @cleanupView()

  cleanupView: ->
    delete @event
    @selectedFriends = []
    @selectedFriendIds = {}
    @invitedUserIds = {}

  buildItems: ->
    # Make a copy of the user's friends so that when the
    #   user selects the friend in one section,
    #   they get selected in every section.
    friends = angular.copy @Auth.user.friends

    # Build the list of alphabetically sorted nearby friends.
    @nearbyFriends = (friend for id, friend of friends \
      when @Auth.isNearby(friend))
    @nearbyFriends.sort (a, b) ->
      if a.name.toLowerCase() < b.name.toLowerCase()
        return -1
      else
        return 1

    # Save nearby friends' ids.
    @nearbyFriendIds = {}
    for nearbyFriend in @nearbyFriends
      @nearbyFriendIds[nearbyFriend.id] = true

    # Build the list of alphabetically sorted items.
    friends = (friend for id, friend of friends)
    friends.sort (a, b) ->
      if a.name.toLowerCase() < b.name.toLowerCase()
        return -1
      else
        return 1
    alphabeticalItems = []
    currentLetter = null
    for friend in friends
      if friend.name[0] != currentLetter
        alphabeticalItems.push
          isDivider: true
          title: friend.name[0]
        currentLetter = friend.name[0]

      alphabeticalItems.push
        isDivider: false
        friend: friend

    # Build the list of items to show in the collection.
    @items = []
    if @nearbyFriends.length > 0
      @items.push
        isDivider: true
        title: 'Nearby Friends'
    for friend in @nearbyFriends
      @items.push
        isDivider: false
        friend: friend
    for item in alphabeticalItems
      @items.push item

  toggleSelected: (friend) ->
    if @getWasSelected friend
      @deselectFriend friend
    else
      @selectFriend friend

  toggleAllNearbyFriends: ->
    if not @isAllNearbyFriendsSelected
      @isAllNearbyFriendsSelected = true
      for friend in @nearbyFriends
        if not @selectedFriendIds[friend.id]
          @selectFriend friend
    else
      @isAllNearbyFriendsSelected = false
      for friend in @nearbyFriends
        @deselectFriend friend

  selectFriend: (friend) ->
    # Don't do anything if the friend was already invited.
    if @getWasInvited friend
      return

    @selectedFriends.push friend
    @selectedFriendIds[friend.id] = true

  deselectFriend: (friend) ->
    # Don't do anything if the friend was already invited.
    if @getWasInvited friend
      return

    # Deselect the all nearby friends toggle if the friend is nearby.
    if @isAllNearbyFriendsSelected
      if @nearbyFriendIds[friend.id]
        @isAllNearbyFriendsSelected = false

    @selectedFriends = (_friend for _friend in @selectedFriends \
        when _friend isnt friend)
    delete @selectedFriendIds[friend.id]

  sendInvitations: ->
    @$ionicLoading.show
      template: '''
        <div class="loading-text">
          Sending suggestion...
        </div>
        <ion-spinner icon="bubbles"></ion-spinner>
        '''

    if 'id' of @event
      # Invite more people to an existing event.
      invitations = ({toUserId: friend.id} \
            for friend in @selectedFriends)
      eventId = @event.id

      @Invitation.bulkCreate eventId, invitations
        .then =>
          @$ionicHistory.clearCache()
        .then =>
          @cleanupView()
          @$ionicHistory.goBack()
        , =>
          @error = 'inviteError'
        .finally =>
          @$ionicLoading.hide()
    else
      # Create a new event.

      # Create the user's friends' invitations.
      invitations = (@Invitation.serialize {toUserId: friend.id} \
          for friend in @selectedFriends)

      # Create the current user's invitation.
      invitations.push @Invitation.serialize
        toUserId: @Auth.user.id

      @event.invitations = invitations
      @Event.save @event
        .$promise.then =>
          @$ionicHistory.clearCache()
        .then =>
          @cleanupView()
          @$state.go 'events'
        , =>
          @error = 'inviteError'
        .finally =>
          @$ionicLoading.hide()

  addFriends: ->
    @cleanupViewAfterLeave = false
    @$state.go 'addFriends'

  getWasSelected: (friend) ->
    @selectedFriendIds[friend.id] is true

  getWasInvited: (friend) ->
    @invitedUserIds[friend.id] is true

module.exports = InviteFriendsCtrl
