require 'angular'
require 'angular-ui-router'
require '../common/friendship-button/friendship-button-module'
AddFromAddressBookCtrl = require './add-from-address-book-controller'

angular.module 'down.addFromAddressBook', [
    'ui.router'
    'ionic'
    'down.friendshipButton'
  ]
  .config ($stateProvider) ->
    $stateProvider.state 'addFromAddressBook',
      url: '/add-from-address-book'
      templateUrl: 'app/add-from-address-book/add-from-address-book.html'
      controller: 'AddFromAddressBookCtrl as addFromAddressBook'
  .controller 'AddFromAddressBookCtrl', AddFromAddressBookCtrl
