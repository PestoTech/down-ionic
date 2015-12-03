class InterestedCtrl
  @$inject: ['$scope', '$stateParams', 'Auth', 'Event', 'ngToast']
  constructor: (@$scope, @$stateParams, @Auth, @Event, @ngToast) ->
    @event = @$stateParams.event

    @$scope.$on '$ionicView.beforeEnter', =>
      @getInterested()

  getInterested: ->
    @Event.interested(@event.id).$promise
      .then (users) =>
        @users = users
        @items = @buildItems()
      , =>
        @ngToast.create 'Oops.. an error occurred..'

  buildItems: ->
    items = []

    items.push
      isDivider: false
      user: @Auth.user

    # Sort by friends or connections
    interestedFriends = []
    interestedConnections = []
    for user in @users
      if @Auth.isFriend user.id
        interestedFriends.push
          isDivider: false
          user: user
      else
        interestedConnections.push 
          isDivider: false
          user: user

    # Add to items array
    if interestedFriends.length > 0
      items.push
        isDivider: true
        title: 'Friends'
      items = items.concat interestedFriends
    if interestedConnections.length > 0
      items.push
        isDivider: true
        title: 'Connections'
      items = items.concat interestedConnections

    items


module.exports = InterestedCtrl
