require 'angular'
require 'angular-mocks'
TutorialCtrl = require './tutorial-controller'

describe 'tutorial controller', ->
  Auth = null
  ctrl = null
  localStorage = null
  scope = null

  beforeEach angular.mock.module('rallytap.auth')

  beforeEach inject(($injector) ->
    $controller = $injector.get '$controller'
    Auth = $injector.get 'Auth'
    scope = $injector.get '$rootScope'

    ctrl = $controller TutorialCtrl,
      $scope: scope
      Auth: Auth
  )

  it 'should init the current section', ->
    expect(ctrl.currentSection).toBe 0

  describe 'before entering the view', ->

    describe 'when the user has an id', ->

      beforeEach ->
        Auth.user = {id: 1}

        scope.$broadcast '$ionicView.beforeEnter'
        scope.$apply()

      it 'should set a flag', ->
        expect(ctrl.isAuthenticated).toBe true


    describe 'when the user doesn\'t have an id', ->

      beforeEach ->
        Auth.user = {}

        scope.$broadcast '$ionicView.beforeEnter'
        scope.$apply()

      it 'should set a flag', ->
        expect(ctrl.isAuthenticated).toBe false


  ##isCurrentSection
  describe 'checking if a section is the current section', ->

    beforeEach ->
      ctrl.currentSection = 0

    describe 'when it is', ->

      it 'should return true', ->
        expect(ctrl.isCurrentSection ctrl.currentSection).toBe true


    describe 'when it isn\'t', ->

      it 'should return false', ->
        expect(ctrl.isCurrentSection ctrl.currentSection+1).toBe false


  ##continue
  describe 'continuing to the next view', ->

    beforeEach ->
      spyOn Auth, 'redirectForAuthState'
      spyOn Auth, 'setFlag'

      ctrl.continue()

    it 'should redirect for auth state', ->
      expect(Auth.redirectForAuthState).toHaveBeenCalled()

    it 'should set a flag in local storage', ->
      expect(Auth.setFlag).toHaveBeenCalledWith 'hasViewedTutorial', true


  ##setSection
  describe 'setting the section', ->
    section = null

    beforeEach ->
      ctrl.currentSection = 0
      section = 1

      ctrl.setSection section

    it 'should set the section on the controller', ->
      expect(ctrl.currentSection).toBe section
