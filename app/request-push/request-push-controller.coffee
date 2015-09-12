class RequestPushCtrl
  @$inject: ['$cordovaDevice', '$cordovaPush', 'APNSDevice', 'Auth',
             'localStorageService']
  constructor: (@$cordovaDevice, @$cordovaPush, @APNSDevice, @Auth,
                localStorageService) ->
    @localStorage = localStorageService

  enablePush: ->
    # iOS Notification Permissions Options
    iosConfig =
      badge: true
      sound: true
      alert: true
    @$cordovaPush.register iosConfig
      .then (deviceToken) =>
        @saveToken deviceToken

    @localStorage.set 'hasRequestedPushNotifications', true
    @Auth.redirectForAuthState()

  saveToken: (deviceToken)->
    device = @$cordovaDevice.getDevice()
    name = "#{device.model}, #{device.version}"
    apnsDevice =
      userId: @Auth.user.id
      registrationId: deviceToken
      deviceId: device.uuid
      name: name
    @APNSDevice.save apnsDevice

module.exports = RequestPushCtrl
