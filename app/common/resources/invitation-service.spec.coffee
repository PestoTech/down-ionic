require 'angular'
require 'angular-mocks'
require './resources-module'

describe 'invitation service', ->
  $httpBackend = null
  Auth = null
  Event = null
  listUrl = null
  Invitation = null
  User = null

  beforeEach angular.mock.module('down.resources')

  beforeEach angular.mock.module(($provide) ->
    Auth =
      user:
        id: 1
    $provide.value 'Auth', Auth
    return
  )

  beforeEach inject(($injector) ->
    $httpBackend = $injector.get '$httpBackend'
    apiRoot = $injector.get 'apiRoot'
    Event = $injector.get 'Event'
    Invitation = $injector.get 'Invitation'
    User = $injector.get 'User'

    listUrl = "#{apiRoot}/invitations"
  )

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'should have a no response property', ->
    expect(Invitation.noResponse).toBe 0

  it 'should have an accepted property', ->
    expect(Invitation.accepted).toBe 1

  it 'should have a declined property', ->
    expect(Invitation.declined).toBe 2

  it 'should have a maybe property', ->
    expect(Invitation.maybe).toBe 3

  describe 'serializing an invitation', ->
    invitation = null

    beforeEach ->
      invitation =
        toUserId: 3

    describe 'with the min amount of data', ->

      it 'should return the serialized invitation', ->
        expectedInvitation =
          to_user: invitation.toUserId
        expect(Invitation.serialize invitation).toEqual expectedInvitation


    describe 'with the max amount of data', ->

      beforeEach ->
        invitation = angular.extend invitation,
          id: 1
          eventId: 2
          fromUserId: 4
          response: Invitation.accepted
          previouslyAccepted: false
          toUserMessaged: false
          muted: false
          lastViewed: new Date()

      it 'should return the serialized invitation', ->
        expectedInvitation =
          id: invitation.id
          event: invitation.eventId
          to_user: invitation.toUserId
          from_user: invitation.fromUserId
          response: invitation.response
          previously_accepted: invitation.previouslyAccepted
          to_user_messaged: invitation.toUserMessaged
          muted: invitation.muted
          last_viewed: invitation.lastViewed.getTime()
        expect(Invitation.serialize invitation).toEqual expectedInvitation


  describe 'deserializing an invitation', ->
    response = null
    expectedInvitation = null
    event = null
    toUser = null
    fromUser = null

    beforeEach ->
      response =
        id: 1
        response: Invitation.accepted
        previously_accepted: false
        to_user_messaged: false
        muted: false
        created_at: new Date().getTime()
        updated_at: new Date().getTime()
        last_viewed: new Date().getTime()
      event =
        id: 2
        title: 'bars?!??!'
        creator: 3
        canceled: false
        datetime: new Date().getTime()
        created_at: new Date().getTime()
        updated_at: new Date().getTime()
        place:
          name: 'Fuku'
          geo:
            type: 'Point'
            coordinates: [40.7285098, -73.9871264]
      fromUser =
        id: 1
        email: 'aturing@gmail.com'
        name: 'Alan Turing'
        username: 'tdog'
        image_url: 'https://facebook.com/profile-pic/tdog'
        location:
          type: 'Point'
          coordinates: [40.7265834, -73.9821535]
      toUser =
        id: 2
        email: 'jclarke@gmail.com'
        name: 'Joan Clarke'
        username: 'jmamba'
        image_url: 'http://imgur.com/jcke'
        location:
          type: 'Point'
          coordinates: [40.7265836, -73.9821539]
      expectedInvitation =
        id: response.id
        eventId: event.id
        toUserId: toUser.id
        fromUserId: fromUser.id
        response: response.response
        previouslyAccepted: response.previously_accepted
        toUserMessaged: response.to_user_messaged
        muted: response.muted
        createdAt: new Date(response.created_at)
        updatedAt: new Date(response.updated_at)
        lastViewed: new Date(response.last_viewed)

    describe 'when the relations are ids', ->

      beforeEach ->
        response.event = event.id
        response.to_user = toUser.id
        response.from_user = fromUser.id

      it 'should return the deserialized invitation', ->
        expect(Invitation.deserialize response).toEqual expectedInvitation


    describe 'when the relations are objects', ->

      beforeEach ->
        response.event = event
        response.to_user = toUser
        response.from_user = fromUser

      it 'should return the deserialized invitation', ->
        expectedInvitation = angular.extend {}, expectedInvitation,
          event: Event.deserialize event
          fromUser: User.deserialize fromUser
          toUser: User.deserialize toUser
        expect(Invitation.deserialize response).toEqual expectedInvitation


  describe 'bulk creating', ->
    invitations = null
    response = null
    responseData = null

    beforeEach ->
      invitation1 =
        eventId: 1
        toUserId: 2
      invitation2 = angular.extend {}, invitation1, {toUserId: 3}
      invitations = [invitation1, invitation2]

      # Mock an array of invitations for the post data.
      invitationsPostData = (Invitation.serialize invitation \
          for invitation in invitations)
      postData = invitations: invitationsPostData

      # Give each invitation in the response data a different id.
      i = 1
      responseData = []
      for invitation in invitationsPostData
        responseData.push angular.extend
          id: i
          from_user: 3
          response: Invitation.noResponse
          previously_accepted: false
          to_user_messaged: false
          muted: false
          created_at: new Date()
          updated_at: new Date()
        , invitation
        i += 1

      $httpBackend.expectPOST listUrl, postData
        .respond 201, angular.toJson(responseData)

      Invitation.bulkCreate invitations
        .$promise.then (_response_) ->
          response = _response_
      $httpBackend.flush 1

    it 'should POST the invitations', ->
      expectedInvitations = (Invitation.deserialize invitation \
          for invitation in responseData)
      expect(response).toAngularEqual expectedInvitations


  describe 'updating an invitation', ->
    invitation = null
    response = null
    responseData = null

    beforeEach ->
      invitation =
        id: 4
        eventId: 1
        toUserId: 2
        fromUserId: 3
        response: Invitation.noResponse
        previouslyAccepted: false
        toUserMessaged: false
        muted: false
      putData = Invitation.serialize invitation
      responseData = angular.extend {}, putData,
        created_at: new Date()
        updated_at: new Date()
        last_viewed: new Date()
      url = "#{listUrl}/#{invitation.id}"
      $httpBackend.expectPUT url, putData
        .respond 201, angular.toJson(responseData)

      Invitation.update invitation
        .$promise.then (_response_) ->
          response = _response_
      $httpBackend.flush 1

    it 'should PUT the invitation', ->
      expectedInvitation = angular.extend {}, invitation,
        createdAt: responseData.created_at
        updatedAt: responseData.updated_at
        lastViewed: responseData.last_viewed
      expect(response).toAngularEqual expectedInvitation


  describe 'fetching event members\' invitations', ->
    response = null
    invitation = null

    beforeEach ->
      event =
        id: 1
        title: 'bars?!?!!?'
        creatorId: 1
        canceled: false
        datetime: new Date()
        createdAt: new Date()
        updatedAt: new Date()
        place:
          name: 'B Bar & Grill'
          lat: 40.7270718
          long: -73.9919324
      invitation =
        id: 1
        event: event.id
        to_user:
          id: 1
          email: 'aturing@gmail.com'
          name: 'Alan Turing'
          username: 'tdog'
          image_url: 'https://facebook.com/profile-pic/tdog'
          location:
            type: 'Point'
            coordinates: [40.7265834, -73.9821535]
        from_user: 4
        response: Invitation.accepted
        previously_accepted: false
        to_user_messaged: false
        muted: false
        created_at: new Date()
        updated_at: new Date()
      url = "#{Event.listUrl}/#{event.id}/invitations"
      responseData = [invitation]
      $httpBackend.expectGET url
        .respond 200, angular.toJson(responseData)

      Invitation.getEventInvitations {id: event.id}
        .$promise.then (_response_) ->
          response = _response_
      $httpBackend.flush 1

    it 'should GET the invitations', ->
      invitations = [Invitation.deserialize invitation]
      expect(response).toAngularEqual invitations


  describe 'fetching the logged in user\'s invitations', ->
    url = null

    beforeEach ->
      url = "#{User.listUrl}/invitations"

    describe 'successfully', ->
      responseData = null
      response = null

      beforeEach ->
        responseData = [
          id: 1
          event:
            id: 2
            title: 'bars?!??!'
            creator: 3
            canceled: false
            datetime: new Date().getTime()
            created_at: new Date().getTime()
            updated_at: new Date().getTime()
            place:
              name: 'Fuku'
              geo:
                type: 'Point'
                coordinates: [40.7285098, -73.9871264]
          to_user: Auth.user.id
          from_user:
            id: 2
            email: 'jclarke@gmail.com'
            name: 'Joan Clarke'
            username: 'jmamba'
            image_url: 'http://imgur.com/jcke'
            location:
              type: 'Point'
              coordinates: [40.7265836, -73.9821539]
          response: Invitation.accepted
          previously_accepted: false
          to_user_messaged: false
          muted: false
          created_at: new Date().getTime()
          updated_at: new Date().getTime()
        ]

        $httpBackend.expectGET url
          .respond 200, angular.toJson(responseData)

        Invitation.getMyInvitations().then (_response_) ->
          response = _response_
        $httpBackend.flush 1

      it 'should GET the invitations', ->
        # Set the returned ids on the original invitations.
        expectedInvitations = [Invitation.deserialize responseData[0]]
        expect(response).toAngularEqual expectedInvitations


    describe 'with an error', ->
      rejected = null

      beforeEach ->
        $httpBackend.expectGET url
          .respond 500, null

        rejected = false
        Invitation.getMyInvitations().then null, ->
          rejected = true
        $httpBackend.flush 1

      it 'should reject the promise', ->
        expect(rejected).toBe true
