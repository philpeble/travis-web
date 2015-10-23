`import Ember from 'ember'`
`import Ajax from 'travis/utils/ajax'`
`import config from 'travis/config/environment'`

Controller = Ember.Controller.extend
  needs: ['currentUser']
  userBinding: 'controllers.currentUser.model'

  store: Ember.inject.service()
  currentUserBinding: 'auth.currentUser'

  userName: (->
    @get('user.name') || @get('user.login')
  ).property('user.login', 'user.name')

  gravatarUrl: (->
    "#{location.protocol}//www.gravatar.com/avatar/#{@get('user.gravatarId')}?s=48&d=mm"
  ).property('user.gravatarId')

  defineTowerColor: (broadcastArray) ->
    if broadcastArray.length
      if broadcastArray.findBy('category', 'warning')
        return 'warning'
      else if broadcastArray.findBy('category', 'announcement')
        return 'announcement'
      else
        return ''

  broadcasts: (->

    if @get('auth.signedIn')
      broadcasts = Ember.ArrayProxy.create(
        content: [],
        lastBroadcastStatus: '',
        isLoading: true
      )
      apiEndpoint = config.apiEndpoint
      options = {}
      options.type = 'GET'
      options.headers = { Authorization: "token #{@auth.token()}" }

      seenBroadcasts = Travis.storage.getItem('travis.seen_broadcasts')
      if seenBroadcasts
        seenBroadcasts = JSON.parse(seenBroadcasts)
      else
        seenBroadcasts = []

      $.ajax("#{apiEndpoint}/v3/broadcasts", options).then (response) =>
        if response.broadcasts.length
          receivedBroadcasts = response.broadcasts.filter((broadcast) =>
              unless broadcast.expired
                if seenBroadcasts.indexOf(broadcast.id.toString()) == -1
                  broadcast
            ).map( (broadcast) ->
              Ember.Object.create(broadcast)
            ).reverse()

        broadcasts.set('lastBroadcastStatus', @defineTowerColor(receivedBroadcasts))
        broadcasts.set('content', receivedBroadcasts)
        broadcasts.set('isLoading', false)

      broadcasts
  ).property('broadcasts')

  actions: {
    toggleBurgerMenu: ->
      @toggleProperty('is-open')
      return false

    toggleBroadcasts: ->
      @toggleProperty('showBroadcasts')
      return false

    markBroadcastAsSeen: (broadcast) ->
      id = broadcast.get('id').toString()
      seenBroadcasts = Travis.storage.getItem('travis.seen_broadcasts')
      if seenBroadcasts
        seenBroadcasts = JSON.parse(seenBroadcasts) 
      else
        seenBroadcasts = []
      seenBroadcasts.push(id)
      Travis.storage.setItem('travis.seen_broadcasts', JSON.stringify(seenBroadcasts))
      @get('broadcasts.content').removeObject(broadcast)
      @set('broadcasts.lastBroadcastStatus', @defineTowerColor(@get('broadcasts.content')))
      return false
  }

  showCta: (->
    !@get('auth.signedIn') && !@get('config.pro') && !@get('landingPage')
  ).property('auth.signedIn', 'landingPage')

`export default Controller`
