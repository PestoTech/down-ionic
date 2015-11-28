class CreateEventCtrl
  @$inject: ['$cordovaDatePicker', '$filter',
             '$ionicModal', '$scope', '$state',
             'Auth', 'Event', 'ngToast']
  constructor: (@$cordovaDatePicker, @$filter,
                @$ionicModal, @$scope, @$state,
                @Auth, @Event, @ngToast) ->
    # Init the view.
    @currentUser = @Auth.user

    # Init the set place modal.
    @$ionicModal.fromTemplateUrl 'app/set-place/set-place.html',
        scope: @$scope
        animation: 'slide-in-up'
      .then (modal) =>
        @setPlaceModal = modal

    # Set functions to control the place modal on the scope so that they can be
    # called from inside the modal.
    @$scope.hidePlaceModal = =>
      @setPlaceModal.hide()

    # Clean up the set place modal after hiding it.
    @$scope.$on '$destroy', =>
      @setPlaceModal.remove()

    @$scope.$on 'placeAutocomplete:placeChanged', (event, place) =>
      @place =
        name: place.name
        lat: place.geometry.location.lat()
        long: place.geometry.location.lng()
      @$scope.hidePlaceModal()

  showSetPlaceModal: ->
    @setPlaceModal.show()

  showDatePicker: ->
    options =
      mode: 'datetime' # This can be anything other than 'date' or 'time'
      allowOldDates: false
      doneButtonLabel: 'Set Date'
    if @datetime
      options.date = @datetime
    else
      options.date = new Date()
    @$cordovaDatePicker.show options
      .then (date) =>
        @datetime = date
        @dateString = @$filter('date') @datetime, "EEE, MMM d 'at' h:mm a"

  getNewEvent: ->
    newEvent = {}
    if @title
      newEvent.title = @title
    else
      newEvent.title = 'hang out'
    if @datetime
      newEvent.datetime = @datetime
    if @place
      newEvent.place = @place

    newEvent

  createEvent: ->
    newEvent = @getNewEvent()
    @Event.save(newEvent).$promise
      .then (event) =>
        delete @title
        delete @datetime
        delete @place
      , =>
        @ngToast.create 'Oops.. an error occurred..'

module.exports = CreateEventCtrl
