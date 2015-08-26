require 'angular'
require 'angular-chart.js'
require 'angular-elastic'
require 'angular-ui-router'
require '../common/asteroid/asteroid-module'
require '../common/place-autocomplete/place-autocomplete-module'
require '../common/resources/resources-module'
require '../common/view-location/view-location-module'
EventsCtrl = require './events-controller'

angular.module 'down.events', [
    'chart.js'
    'down.asteroid'
    'down.placeAutocomplete'
    'down.resources'
    'down.viewLocation'
    'ionic'
    'monospaced.elastic'
    'ui.router'
  ]
  .config ($stateProvider) ->
    $stateProvider.state 'events',
      url: '/'
      templateUrl: 'app/events/events.html'
      controller: 'EventsCtrl as events'
  .controller 'EventsCtrl', EventsCtrl
  .value 'dividerHeight', 41 # px
  .value 'eventHeight', 78 # px
  .value 'transitionDuration', 450 # ms
