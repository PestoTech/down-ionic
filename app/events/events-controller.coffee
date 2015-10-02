class EventsCtrl
  @$inject: ['$cordovaDatePicker', '$ionicHistory', '$ionicLoading', '$ionicModal',
             '$ionicPlatform', '$meteor', '$scope', '$state', '$timeout', 'Auth',
             'Invitation', 'ngToast', 'User']
  constructor: (@$cordovaDatePicker, @$ionicHistory, @$ionicLoading, @$ionicModal,
                @$ionicPlatform, @$meteor, @$scope, @$state, @$timeout, @Auth,
                @Invitation, @ngToast, @User) ->
    # Set Meteor collections on controller
    @EventMessages = @$meteor.getCollectionByName 'eventMessages'
    @Events = @$meteor.getCollectionByName 'events'

    # Init the set place modal.
    @$ionicModal.fromTemplateUrl 'app/set-place/set-place.html',
        scope: @$scope
        animation: 'slide-in-up'
      .then (modal) =>
        @setPlaceModal = modal

    # Set functions to control the place modal on the scope so that they can be
    # called from inside the modal.
    @$scope.hidePlaceModal = =>
      @setPlaceModal.hide()

    # Update the new event's place when the user selects a place.
    @$scope.$on 'placeAutocomplete:placeChanged', (event, place) =>
      @newEvent.hasPlace = true
      @newEvent.place =
        name: place.name
        lat: place.geometry.location.lat()
        long: place.geometry.location.lng()
      @$scope.hidePlaceModal()

    # Clean up the set place modal after hiding it.
    @$scope.$on '$destroy', =>
      @setPlaceModal.remove()

    # Fetch the invitations to show on the view.
    @manualRefresh()

    @newEvent = {}

    # Refresh the feed when the user comes back to the app.
    @$ionicPlatform.on 'resume', @manualRefresh

  toggleHasDate: ->
    if not @newEvent.hasDate
      options =
        mode: 'datetime' # This can be anything other than 'date' or 'time'
        allowOldDates: false
        doneButtonLabel: 'Set Date'
      # If the user has set the date before, use the previous date they set.
      if angular.isDate @newEvent.datetime
        options.date = @newEvent.datetime
      else
        options.date = new Date()
      @$cordovaDatePicker.show options
        .then (date) =>
          if date?
            @newEvent.datetime = date
            @newEvent.hasDate = true
    else
      @newEvent.hasDate = false

  toggleHasPlace: ->
    if not @newEvent.hasPlace
      @setPlaceModal.show()
    else
      @newEvent.hasPlace = false

  toggleHasComment: ->
    if not @newEvent.hasComment
      @newEvent.hasComment = true
    else
      @newEvent.hasComment = false

  buildItems: (invitationsDict) ->
    # Build the list of items to show on the view.
    items = []

    invitations = (invitation for id, invitation of invitationsDict)
    invitations.sort (a, b) ->
      aCreatedAt = a.event.latestMessage?.createdAt or a.event.createdAt
      bCreatedAt = b.event.latestMessage?.createdAt or b.event.createdAt
      if aCreatedAt > bCreatedAt
        return -1
      else
        return 1
    if invitations.length > 0
      title = 'Plans'
      items.push
        isDivider: true
        title: title
        id: title
      for invitation in invitations
        items.push angular.extend
          isDivider: false
          invitation: invitation
          id: invitation.id
          # DON'T SET THE METEOR ANGULAR VARIABLES ON THE EVENT ITSELF!!
          #   AngularMeteorObject.getRawObject() breaks... not sure why...
          #   When passing an AngularMeteorObject into $state.go, AngularMeteor.getRawObject()
          #   is automatically called. Therefore, do not pass AngularMeteorObjects into $state.go.
          newestMessage: @getNewestMessage "#{invitation.event.id}"

    friends = (friend for id, friend of @Auth.user.friends \
        when friend.username isnt null)
    if friends.length > 0
      title = 'Friends'
      items.push
        isDivider: true
        title: title
        id: title
      for friend in friends
        items.push angular.extend
          isDivider: false
          friend: new @User friend
          id: friend.id

    items

  eventsEventMessagesSubscribe: (events) ->
    # Subscribe to the eventMessages posted in each event.
    for event in events
      @$scope.$meteorSubscribe 'event', "#{event.id}"

  getNewestMessage: (eventId) =>
    selector =
      eventId: eventId
    options =
      sort:
        createdAt: -1
      transform: @transformMessage
    @$scope.$meteorObject @EventMessages, selector, false, options

  transformMessage: (message) =>
    # Show senders first name
    if message.type is 'text'
      firstName = message.creator.firstName
      message.text = "#{firstName}: #{message.text}"

    # Bind meteorEvent for checking wasRead
    message.meteorEvent = @$scope.$meteorObject @Events, message.eventId, false

    message

  wasRead: (message) =>
    members = message.meteorEvent?.members or []
    lastRead = (member.lastRead for member in members when "#{@Auth.user.id}" is member.userId)[0]
    lastRead >= message.createdAt

  #   # Move the event's updated item.
  #   for item in @items
  #     if item.invitation?.event.id is event.id
  #       @items = @buildItems @invitations


  acceptInvitation: (item, $event) ->
    @respondToInvitation item, $event, @Invitation.accepted

  maybeInvitation: (item, $event) ->
    @respondToInvitation item, $event, @Invitation.maybe

  declineInvitation: (item, $event) ->
    @respondToInvitation item, $event, @Invitation.declined

  respondToInvitation: (item, $event, response) ->
    # Prevent calling the ion-item element's ng-click.
    $event.stopPropagation()

    invitation = @invitations[item.invitation.id]
    @Invitation.updateResponse invitation, response
      .$promise.then null, =>
        @items = @buildItems @invitations
        @ngToast.create 'For some reason, that didn\'t work.'

    @items = @buildItems @invitations

  inviteFriends: ->
    # Don't animate the transition to the invite friends view.
    @$ionicHistory.nextViewOptions
      disableAnimate: true

    newEvent = @getNewEvent()
    @$state.go 'inviteFriends', {event: newEvent}

  getNewEvent: ->
    event = {title: @newEvent.title}
    if @newEvent.hasDate
      event.datetime = @newEvent.datetime
    if @newEvent.hasPlace
      event.place = @newEvent.place
    if @newEvent.hasComment
      event.comment = @newEvent.comment
    event

  myFriends: ->
    # Don't animate the transition to the invite friends view.
    @$ionicHistory.nextViewOptions
      disableAnimate: true

    @$state.go 'friends'

  viewEvent: (item) ->
    @$state.go 'event',
      invitation: item.invitation
      id: item.invitation.event.id

  getInvitations: ->
    @Invitation.getMyInvitations()
      .then (invitations) =>
        # Save the invitations on the controller.
        @invitations = {}
        for invitation in invitations
          @invitations[invitation.id] = invitation

        # Build the list of items to show in the view.
        @items = @buildItems @invitations

        # Subscribe to the eventMessages for each event.
        events = (invitation.event for invitation in invitations)
        @eventsEventMessagesSubscribe events

        # Set `percentRemaining` as a property on each event as a workaround for
        #   stopping angular-chart.js from calling `getPercentRemaining` too many
        #   times.
        for event in events
          event.percentRemaining = event.getPercentRemaining()
      , =>
        @getInvitationsError = true
      .finally =>
        @$scope.$broadcast 'scroll.refreshComplete'
        @isLoading = false

  refresh: ->
    @getInvitations()

  manualRefresh: =>
    @isLoading = true
    @getInvitations()

  addByUsername: ->
    @$state.go 'addByUsername'

  addFromAddressBook: ->
    @$state.go 'addFromAddressBook'

  addFromFacebook: ->
    @$state.go 'addFromFacebook'

module.exports = EventsCtrl
