require 'angular-chart.js'
require 'angular-elastic'
require 'ng-toast'
require '../mixpanel/mixpanel-module'
selectFriendButton = require './select-friend-button-directive'

angular.module 'rallytap.selectFriendButton', [
    'angular-meteor'
    'analytics.mixpanel'
    'chart.js'
    'ngToast'
    'ui.router'
  ]
  .directive 'selectFriendButton', selectFriendButton
