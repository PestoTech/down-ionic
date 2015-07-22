intlPhone = ->
  replace: true
  require: 'ngModel'
  template: '<input type="tel">'
  link: (scope, element, attrs, model) ->
    # TODO: Test this.
    # Init the international tel input plugin on the element.
    element.intlTelInput
      utilsScript: '/app/vendor/intl-phone/libphonenumber-utils.js'

    model.$parsers.unshift (value) ->
      # Set the phone number on the model.
      phone = element.intlTelInput 'getNumber'
      model.$setViewValue phone
      phone

    model.$validators.validNumber = (modelValue, viewValue) ->
      element.intlTelInput 'isValidNumber'

    return

module.exports = intlPhone