require 'angular'
require 'angular-mocks'
require '../../vendor/intl-phone/libphonenumber-utils.js'
require '../resources/resources-module'
require './contact-friendship-button-module'

describe 'contact friendship button directive', ->
  $compile = null
  $q = null
  element = null
  scope = null
  UserPhone = null

  beforeEach angular.mock.module('down.contactFriendshipButton')

  beforeEach angular.mock.module('down.resources')

  beforeEach inject(($injector) ->
    $compile = $injector.get '$compile'
    $q = $injector.get '$q'
    $rootScope = $injector.get '$rootScope'
    scope = $rootScope.$new()
    UserPhone = $injector.get 'UserPhone'

    # Mock setting the contact in the current scope.
    scope.contact =
      id: 1
      name: 'Alan Turing'
      phoneNumbers: [
        type: 'mobile'
        value: '2036227310'
        pref: true
      ]

    element = angular.element """
      <contact-friendship-button contact="contact">
      """
    $compile(element) scope
    scope.$digest()
  )

  describe 'tapping the add friend button', ->
    deferred = null

    beforeEach ->
      deferred = $q.defer()
      spyOn(UserPhone, 'create').and.returnValue deferred.promise

      anchor = element.find 'a'
      anchor.triggerHandler 'click'

    it 'should show a spinner', ->
      icon = element.find 'i'
      expect(icon).toHaveClass 'fa-spinner'
      expect(icon).toHaveClass 'fa-pulse'

    it 'should create the userphone', ->
      expect(UserPhone.create).toHaveBeenCalledWith scope.contact

    describe 'when the add succeeds', ->
      contact = null

      beforeEach ->
        contact = angular.extend {}, scope.contact,
          formattedPhone: '(203) 622-7310'
        data =
          contact: contact
          userphone:
            user:
              id: 1
            phone: '+12036227310'
        deferred.resolve data
        scope.$apply()

      it 'should get the contact from local storage', ->
        expect(scope.contact).toEqual contact


    describe 'when the add fails', ->

      beforeEach ->
        deferred.reject()
        scope.$apply()

      it 'should the show add friend button', ->
        icon = element.find 'i'
        expect(icon).toHaveClass 'fa-plus-square-o'
