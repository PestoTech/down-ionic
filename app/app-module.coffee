require 'angular'

angular.module 'down', ['ionic']
  .run ($ionicPlatform, $window) ->
    $ionicPlatform.ready ->
      # Hide the accessory bar by default (remove this to show the accessory bar
      # above the keyboard for form inputs)
      $window.cordova?.plugins.Keyboard?.hideKeyboardAccessoryBar true
      $window.StatusBar?.styleDefault()

    # Allow sending a request body with DELETE request.
    #$httpProvider.defaults.headers.delete =
    #  'Content-Type': 'application/json;charset=utf-8'
