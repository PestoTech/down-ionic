userFriendshipButtonDirective = (Auth, Friendship) ->
  restrict: 'E'
  scope:
    user: '='
  template: """
    <a href="" ng-click="toggleFriendship(user)">
      <i class="icon fa friendship-button"
         ng-if="!isLoading"
         ng-class="{
          'fa-plus-square-o': !isFriend(user),
          'fa-check-square': isFriend(user),
          }"
      ></i>
      <i class="icon" ng-if="isLoading"
          ><ion-spinner icon="bubbles"></ion-spinner></i>
    </a>
    """
  controller: ($scope) ->
    $scope.isFriend = (user) ->
      Auth.isFriend user.id

    $scope.toggleFriendship = (user) ->
      $scope.isLoading = true

      if Auth.isFriend user.id
        Friendship.deleteWithFriendId user.id
          .$promise.then ->
            # Remove the user from the current user's array of friends.
            Auth.user.friends = (friend for friend in Auth.user.friends \
                when friend.id isnt user.id)
            Auth.setUser Auth.user
          .finally ->
            $scope.isLoading = false
      else
        friendship =
          userId: Auth.user.id
          friendId: user.id
        Friendship.save friendship
          .$promise.then ->
            Auth.user.friends.push user
            Auth.setUser Auth.user
          .finally ->
            $scope.isLoading = false

module.exports = userFriendshipButtonDirective
