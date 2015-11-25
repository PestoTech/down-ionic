require 'ng-cordova'
require 'ng-toast'
require '../common/resources/resources-module'
CreateEventCtrl = require './create-event-controller'

angular.module 'rallytap.createEvent', [
    'rallytap.resources'
    'ngCordova'
    'ui.router'
    'ngToast'
  ]
  .config ($stateProvider) ->
    $stateProvider.state 'tabs.post.createEvent',
      url: ''
      templateUrl: 'app/create-event/create-event.html'
      controller: 'CreateEventCtrl as createEvent'
  .controller 'CreateEventCtrl', CreateEventCtrl
