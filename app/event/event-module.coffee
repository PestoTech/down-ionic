require 'angular'
require 'angular-elastic'
require 'angular-ui-router'
require '../common/resources/resources-module'
EventCtrl = require './event-controller'

angular.module 'down.event', [
    'ui.router'
    'monospaced.elastic'
    'down.resources'
  ]
  .config ($stateProvider) ->
    $stateProvider.state 'event',
      url: '/events/:id'
      templateUrl: 'app/event/event.html'
      controller: 'EventCtrl as event'
      params:
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
          previouslyAccepted: false
          toUserMessaged: false
          muted: false
          lastViewed: new Date()
          createdAt: new Date()
          updatedAt: new Date()
        #invitation: null
        id: 1
  .controller 'EventCtrl', EventCtrl
