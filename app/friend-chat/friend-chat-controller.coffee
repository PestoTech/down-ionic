class FriendChatCtrl
  @$inject: ['$ionicScrollDelegate', '$meteor', '$mixpanel',
             '$scope', '$state', '$stateParams', 'Auth',
             'Friendship', 'User']
  constructor: (@$ionicScrollDelegate, @$meteor, @$mixpanel,
                @$scope, @$state, @$stateParams, @Auth,
                @Friendship, @User) ->
    @friend = @$stateParams.friend

    # Set Meteor collections on controller
    @Messages = @$meteor.getCollectionByName 'messages'
    @Chats = @$meteor.getCollectionByName 'chats'

    @$scope.$on '$ionicView.beforeEnter', =>
      @chatId = @Friendship.getChatId @friend.id

      # Bind reactive variables
      @messages = @$meteor.collection @getMessages, false

      # Watch for changes in newest message
      @watchNewestMessage()

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

  isInviteAction: (message) ->
    message.type is 'invite_action'

  isTextMessage: (message) ->
    message.type is 'text'

  isMyMessage: (message) ->
    message.creator.id is "#{@Auth.user.id}"

  sendMessage: ->
    @Friendship.sendMessage @friend, @message
    @$mixpanel.track 'Send Message',
      'chat type': 'friend'
    @message = null

  scrollBottom: ->
    @$ionicScrollDelegate.$getByHandle 'friendChat'
      .scrollBottom true

module.exports = FriendChatCtrl
