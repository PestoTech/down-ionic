class FriendshipCtrl
  @$inject: ['$ionicActionSheet', '$ionicLoading', '$ionicScrollDelegate', '$meteor', '$mixpanel',
             '$scope', '$state', '$stateParams', '$window', 'Auth', 'Invitation',
             'Friendship', 'ngToast', 'User', '$rootScope', 'LinkInvitation']
  constructor: (@$ionicActionSheet, @$ionicLoading, @$ionicScrollDelegate, @$meteor, @$mixpanel,
                @$scope, @$state, @$stateParams, @$window, @Auth, @Invitation,
                @Friendship, @ngToast, @User, @$rootScope, @LinkInvitation) ->
    @friend = @$stateParams.friend

    # Set Meteor collections on controller
    @Messages = @$meteor.getCollectionByName 'messages'
    @Chats = @$meteor.getCollectionByName 'chats'
    @Matches = @$meteor.getCollectionByName 'matches'
    @MembersCount = @$meteor.getCollectionByName 'membersCount'

    @$scope.$on '$ionicView.beforeEnter', =>
      @getFriendInvitations()
      @chatId = @Friendship.getChatId @friend.id

      # Subscribe to the event's chat.
      @$scope.$meteorSubscribe 'chat', @chatId

      # Bind reactive variables
      @messages = @$meteor.collection @getMessages, false
      @match = @getMatch()

      # Watch for changes in newest message
      @watchNewestMessage()

      @$rootScope.hideNavBottomBorder = angular.isDefined @match._id

    @$scope.$on '$ionicView.leave', =>
      # Remove angular-meteor bindings.
      @messages.stop()

  watchNewestMessage: =>
    # Mark messages as read as they come in
    #   and scroll to bottom
    @$scope.$watch =>
      newestMessage = @messages[@messages.length-1]
      if angular.isDefined newestMessage
        newestMessage._id
    , @handleNewMessage

  handleNewMessage: (newMessageId) =>
    if newMessageId is undefined
      return

    @$meteor.call 'readMessage', newMessageId
    @scrollBottom()

    # If the newest message is an invite action, attach the invitation to the
    #   message.
    newestMessage = @messages[@messages.length-1]
    if newestMessage.type is @Invitation.inviteAction
      @getFriendInvitations()

  ###
  # Get the active invitations to/from the friend.
  ###
  getFriendInvitations: ->
    @Invitation.getUserInvitations @friend.id
      .$promise.then (invitations) =>
        # Set the invitations on their corresponding messages objects. If an
        #   invite action message exists without a corresponding invitation,
        #   remove the message.
        events = {}
        for invitation in invitations
          events[invitation.eventId] = invitation

        for message in @messages
          if message?.type is @Invitation.inviteAction
            invitation = events[message.meta.eventId]
            if angular.isDefined invitation
              message.invitation = invitation
              # If event is a locked event, subscribe 
              #   to the members count and bid the data
              if angular.isDefined invitation.event.minAccepted
                eventId = "#{invitation.eventId}"
                @$scope.$meteorSubscribe 'membersCount', eventId
                message.membersCount = @$scope.$meteorObject @MembersCount, eventId, false
            else
              # Delete expired invite_action message
              @messages.remove message._id

        @scrollBottom()
      , =>
        # Change all invitation action messages to error action messages.
        for message in @messages
          if message.type is @Invitation.inviteAction
            message.type = @Invitation.errorAction

  getMessages: =>
    @Messages.find
      chatId: @chatId
    ,
      sort:
        createdAt: 1
      transform: @transformMessage

  transformMessage: (message) =>
    message.creator = new @User message.creator
    message

  getMatch: =>
    selector =
      $or: [
        firstUserId: "#{@friend.id}"
      ,
        secondUserId: "#{@friend.id}"
      ]
    @$scope.$meteorObject @Matches, selector, false

  isActionMessage: (message) ->
    actions = [
      @Invitation.acceptAction
      @Invitation.maybeAction
      @Invitation.declineAction
    ]
    message.type in actions

  isInviteAction: (message) ->
    message.type is @Invitation.inviteAction

  isTextMessage: (message) ->
    message.type is @Invitation.textMessage

  isLoadingInvitation: (message) ->
    message.type is @Invitation.inviteAction and message.invitation is undefined

  isErrorAction: (message) ->
    message.type is @Invitation.errorAction

  isMyMessage: (message) ->
    message.creator.id is "#{@Auth.user.id}"

  isAccepted: (invitation) ->
    invitation.response is @Invitation.accepted

  isMaybe: (invitation) ->
    invitation.response is @Invitation.maybe

  isDeclined: (invitation) ->
    invitation.response is @Invitation.declined

  wasJoined: (message) ->
    message.invitation.response is @Invitation.accepted \
        or message.invitation.response is @Invitation.maybe

  respondToInvitation: (invitation, response) ->
    @$ionicLoading.show()

    minAccepted = invitation.event.minAccepted
    if response in [@Invitation.accepted, @Invitation.maybe] and \
       minAccepted is undefined
      # Not a locked event
      enterChat = true
    else if response is @Invitation.accepted
      # Locked event
      membersCount = @MembersCount.findOne({_id: "#{invitation.eventId}"})?.count
      if minAccepted - membersCount is 1
        # Last member needed to unlock
        enterChat = true


    @Invitation.updateResponse invitation, response
      .$promise.then (invitation) =>
        if enterChat is true
          @$state.go 'event',
            invitation: invitation
            id: invitation.event.id
      , =>
        @ngToast.create 'For some reason, that didn\'t work.'
      .finally =>
        @$ionicLoading.hide()

  acceptInvitation: (invitation) ->
    @respondToInvitation invitation, @Invitation.accepted

  maybeInvitation: (invitation) ->
    @respondToInvitation invitation, @Invitation.maybe

  declineInvitation: (invitation) ->
    @respondToInvitation invitation, @Invitation.declined

  viewEvent: (invitation) ->
    @$state.go 'event',
      invitation: invitation
      id: invitation.event.id

  sendMessage: ->
    @Friendship.sendMessage @friend, @message
    @$mixpanel.track 'Send Message',
      'chat type': 'friend'
    @message = null

  scrollBottom: ->
    @$ionicScrollDelegate.$getByHandle('friendship')
      .scrollBottom true

  getPlaceholder: ->
    distanceAway = @Auth.getDistanceAway @friend.location
    if distanceAway is null
      'Start a chat...'
    else
      "#{@friend.firstName} is #{distanceAway} away"

  isLocked: (message) ->
    minAccepted = message.invitation?.event?.minAccepted
    membersCount = message.membersCount?.count

    # Not a lockable event
    if minAccepted is undefined
      return false
    # Members data not here yet
    if membersCount is undefined
      return true

    membersCount < minAccepted

  shareEvent: (event) ->
    hideSheet = null
    hasSharingPlugin = angular.isDefined @$window.plugins?.socialsharing
    shareText = if hasSharingPlugin then 'Share On...' else 'Copy Group Link'
    options =
      buttons: [
        text: 'Send To...'
      ,
        text: shareText
      ]
      cancelText: 'Cancel'
      buttonClicked: (index) =>
        if index is 0
          @$state.go 'inviteFriends',
            event: event
          hideSheet()
        if index is 1
          @LinkInvitation.share event
          hideSheet()

    hideSheet = @$ionicActionSheet.show options


module.exports = FriendshipCtrl
