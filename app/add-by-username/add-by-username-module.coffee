require '../common/auth/auth-module'
require '../common/friendship-button/friendship-button-module'
require '../common/resources/resources-module'
AddByUsernameCtrl = require './add-by-username-controller'

angular.module 'rallytap.addByUsername', [
    'ui.router'
    'rallytap.auth'
    'rallytap.resources'
    'rallytap.friendshipButton'
  ]
  .config ($stateProvider) ->
    $stateProvider.state 'addByUsername',
      url: '/add-by-username'
      parent: 'friends'
      templateUrl: 'app/add-by-username/add-by-username.html'
      controller: 'AddByUsernameCtrl as addByUsername'
  .controller 'AddByUsernameCtrl', AddByUsernameCtrl
