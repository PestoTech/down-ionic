require 'angular'
require 'angular-resource'
APNSDevice = require './apnsdevice-service'
Event = require './event-service'
Friendship = require './friendship-service'
Invitation = require './invitation-service'
AllFriendsInvitation = require './allfriendsinvitation-service'
LinkInvitation = require './linkinvitation-service'

angular.module 'down.resources', ['ngResource']
  .value 'apiRoot', '/api'
  .factory 'APNSDevice', APNSDevice
  .factory 'Event', Event
  .factory 'Friendship', Friendship
  .factory 'Invitation', Invitation
  .factory 'AllFriendsInvitation', AllFriendsInvitation
  .factory 'LinkInvitation', LinkInvitation
