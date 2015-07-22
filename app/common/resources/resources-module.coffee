require 'angular'
require 'angular-resource'
require '../auth/auth-module'
AllFriendsInvitation = require './allfriendsinvitation-service'
APNSDevice = require './apnsdevice-service'
Event = require './event-service'
Friendship = require './friendship-service'
Invitation = require './invitation-service'
LinkInvitation = require './linkinvitation-service'
User = require './user-service'
UserPhone = require './userphone-service'

angular.module 'down.resources', ['ngResource', 'down.auth']
  .value 'apiRoot', 'http://localhost:5000/api'
  .factory 'APNSDevice', APNSDevice
  .factory 'Event', Event
  .factory 'Friendship', Friendship
  .factory 'Invitation', Invitation
  .factory 'AllFriendsInvitation', AllFriendsInvitation
  .factory 'LinkInvitation', LinkInvitation
  .factory 'User', User
  .factory 'UserPhone', UserPhone
