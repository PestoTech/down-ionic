angular.module 'angular-meteor', []
  .service '$meteor', ->
    @collection = jasmine.createSpy '$meteorCollection'
    @collectionFS = jasmine.createSpy '$meteorCollectionFS'
    @object = jasmine.createSpy '$meteorObject'
    @subscribe = jasmine.createSpy '$meteorSubscribe.subscribe'
    @call = jasmine.createSpy '$meteorMethods.call'
    @loginWithPassword = jasmine.createSpy '$meteorUser.loginWithPassword'
    @requireUser = jasmine.createSpy '$meteorUser.requireUser'
    @requireValidUser = jasmine.createSpy '$meteorUser.requireValidUser'
    @waitForUser = jasmine.createSpy '$meteorUser.waitForUser'
    @createUser = jasmine.createSpy '$meteorUser.createUser'
    @changePassword = jasmine.createSpy '$meteorUser.changePassword'
    @forgotPassword = jasmine.createSpy '$meteorUser.forgotPassword'
    @resetPassword = jasmine.createSpy '$meteorUser.resetPassword'
    @verifyEmail = jasmine.createSpy '$meteorUser.verifyEmail'
    @loginWithMeteorDeveloperAccount = jasmine.createSpy '$meteorUser.loginWithMeteorDeveloperAccount'
    @loginWithFacebook = jasmine.createSpy '$meteorUser.loginWithFacebook'
    @loginWithGithub = jasmine.createSpy '$meteorUser.loginWithGithub'
    @loginWithGoogle = jasmine.createSpy '$meteorUser.loginWithGoogle'
    @loginWithMeetup = jasmine.createSpy '$meteorUser.loginWithMeetup'
    @loginWithTwitter = jasmine.createSpy '$meteorUser.loginWithTwitter'
    @loginWithWeibo = jasmine.createSpy '$meteorUser.loginWithWeibo'
    @logout = jasmine.createSpy '$meteorUser.logout'
    @logoutOtherClients = jasmine.createSpy '$meteorUser.logoutOtherClients'
    @session = jasmine.createSpy '$meteorSession'
    @autorun = jasmine.createSpy '$meteorUtils.autorun'
    @getCollectionByName = jasmine.createSpy '$meteorUtils.getCollectionByName'
    @getPicture = jasmine.createSpy '$meteorCamera.getPicture'
    return
