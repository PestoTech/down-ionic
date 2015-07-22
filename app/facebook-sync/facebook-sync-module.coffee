require 'angular'
require 'angular-ui-router'
require 'ng-cordova'
FacebookSyncCtrl = require './facebook-sync-controller'

angular.module 'down.facebookSync', [
    'ui.router'
    'ngCordova.plugins.oauth'
  ]
  .config ($stateProvider) ->
    $stateProvider.state 'facebookSync',
      url: '/fb-sync'
      templateUrl: 'app/facebook-sync/facebook-sync.html'
      controller: 'FacebookSyncCtrl as fbSync'
  .controller 'FacebookSyncCtrl', FacebookSyncCtrl
  .value 'fbClientId', '864552050271610' # staging