class LoginCtrl
  constructor: (@$scope, @$state, @Auth) ->

  login: ->
    if not @validate()
      return

    @Auth.sendVerificationText(@phone).then =>
      @Auth.redirectForAuthState()
    , =>
      @error = 'For some reason, that didn\'t work'

  validate: ->
    @$scope.loginForm.$valid

module.exports = LoginCtrl
