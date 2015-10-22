require 'angular-elastic'
require 'ng-toast'
require '../common/auth/auth-module'
require '../common/mixpanel/mixpanel-module'
require '../common/resources/resources-module'
require '../common/view-place/view-place-module'
EventCtrl = require './event-controller'

angular.module 'rallytap.event', [
    'angular-meteor'
    'analytics.mixpanel'
    'ionic'
    'ui.router'
    'monospaced.elastic'
    'rallytap.resources'
    'rallytap.auth'
    'rallytap.viewPlace'
    'ngToast'
  ]
  .config ($stateProvider) ->
    $stateProvider.state 'event',
      url: '/events/:id'
      templateUrl: 'app/event/event.html'
      controller: 'EventCtrl as event'
      params:
        ###
        invitation:
          id: 2
          event:
            id: 1
            title: 'bars?!?!!?'
            creator: 1
            canceled: false
            datetime: new Date()
            place:
              name: 'B Bar & Grill'
              lat: 40.7270718
              long: -73.9919324
            comment: 'It\'s too nice outside.'
          response: 1
          muted: false
          lastViewed: new Date()
          createdAt: new Date()
          updatedAt: new Date()
        ###
        invitation: null
  .controller 'EventCtrl', EventCtrl
