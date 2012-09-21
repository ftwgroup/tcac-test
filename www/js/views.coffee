# TODO all views store a collection as the model should probably be a collection instead
directory.views.HomePage = class HomePage extends Backbone.View
	
	initialize: ->
		_.bindAll @
		@template = _.template directory.utils.templateLoader.get 'home-page'

	render: ->
		$(@el).html @template()

directory.views.SearchPage = class SearchPage extends Backbone.View
	
	templateLoader: directory.utils.templateLoader

	events:
		'keyup .search-key':		'search',
		'click a': 							'onClick'

	initialize: ->
		_.bindAll @
		console.log 'SearchPage initialize'
		@template = _.template @templateLoader.get 'search-page'
		@render()

	render: (eventName) ->
		console.log 'SearchPage render'
		$(@el).html @template @model.toJSON()
		params = 
			el: $('.scroll', @el),
			model: @model
		@listView = new directory.views.ContactListView params
		@listView.render()
		@

	search: (event) ->
		console.log 'search'
		key = $('.search-key').val()
		console.log 'key', key
		@model.findByName(key)
		false

	onClick: (event) ->
		$('.search-key').blur() # hide keyboard

directory.views.GroupPage = class GroupPage extends Backbone.View
	
	initialize: ->
		_.bindAll @
		@template = _.template directory.utils.templateLoader.get('group-page')

	render: (eventName) ->
		console.log 'GroupPage render'
		$(@el).html @template @model.toJSON()
		params = 
			el: $('.scroll', @el),
			model: @model
		@listView = new directory.views.ContactListView params
		@listView.render()
		@	

directory.views.CalendarPage = class CalendarPage extends Backbone.View
	events:
		"click .test":  		"showEvents",
		"click .create":		"create"

	initialize: ->
		_.bindAll @
		@template = _.template directory.utils.templateLoader.get 'calendar-page'
		@calendarListTemplate = _.template directory.utils.templateLoader.get 'calendar-list'
		@eventTemplate = _.template directory.utils.templateLoader.get 'event-template'


	render: ->
		console.log 'calendar page'
		$(@el).html @template()
		window.plugins.calendarPlugin.getCalendarList((response)=>
			for calendar in response
				#alert JSON.stringify calendar
				do (calendar) =>
					$('.calendars').append @calendarListTemplate({'name':calendar})
		, (response)->
			console.log 'error', response
		)
		@

	create: (e)->
		console.log "create", e.target
		data = $(e.target).data()
		console.log "data", data
		window.plugins.calendarPlugin.createEvent (res)->
			alert res

	showEvents: (e)->
		console.log "show events"
		window.plugins.calendarPlugin.getEventList (res)=>
			console.log "result", res
			$('ul').empty()
			$('.calendars').hide()
			$('ul').append @eventTemplate res[0]
		, (res)->
			console.log "error result", res
			$('ul').empty()
			$('.calendars').hide()
			$('ul').append '<li class="create">Create and Event</li>'
		e.preventDefault()

directory.views.ContactListView = class ContactListView extends Backbone.View

	initialize: ->
		_.bindAll @
		@model.on 'reset', @render, @

	render: (eventName) ->
		ul = $('ul', @el)
		ul.empty()
		_.each @model.models, (contact) ->
			ul.append new directory.views.ContactListItemView({model:contact}).render().el
		, @
		if @iscroll
			console.log 'Refresh iScroll'
			@iscroll.refresh()
		else
			console.log 'New iScroll'
			@iscroll = new iScroll @el, {hScrollbar:false, vScrollbar:false}
		@

directory.views.ContactListItemView = class ContactListItemView extends Backbone.View

	tagName: 'li'

	initialize: ->
		_.bindAll @
		@template = _.template directory.utils.templateLoader.get 'contact-list-item'

	render: (eventName) ->
		$(@el).html @template @model.toJSON()
		$('<img height="50" width="50" class="list-icon"/>').attr('src', @model.get 'picture')
			.load(=>
				$('.imgHolder', @el).html(this))
			.on('error', (event)->
				$(this).attr 'src', 'img/unknown.jpg')
		@

directory.views.ContactPage = class ContactPage extends Backbone.View

	initialize: ->
		_.bindAll @
		@template = _.template directory.utils.templateLoader.get('contact-page')
		
	render: (eventName) ->
		$(@el).html @template @model.toJSON()
		$('<img height="85" width="85"/>').attr('src', @model.get 'picture')
			.load(=>
				$('.imgHolder', @el).prepend(this))
			.on('error', (envent)->
				$(this).attr 'src', 'img/unknown.jpg')
		setTimeout =>
			@iscroll = new iScroll $('.scroll', @el)[0], {hScrollbar:false, vScrollbar:false}
			@iscroll.refresh()
		, 100
		@

	addContact: ->
		contact = new Contact() # a phonegap contact
		contactName = new ContactName() # a phonegap contact name
		contactName.givenName = @model.get 'firstName'
		contactName.familyname = @model.get 'lastName'
		contact.name = contactName
		contact.phoneNumbers = [
			new ContactField('work', @model.get('officePhone'), false),
			new ContactField('mobile', @model.get('cellPhone'), true) # preferred number
		]
		contact.emails = [
			new ContactField('work', @model.get('email'), true)
		]
		contact.save()
		showAlert(@model.get('firstName') + ' ' + @model.get('lastName') + ' added as Contact', 'Successs')
		false

directory.views.FeedsPage = class FeedsPage extends Backbone.View

	events:
		'click .twitter':		'twitter',
		'click .facebook':	'facebook'

	initialize: ->
		console.log 'feeds page initialized'
		_.bindAll @
		@storage = window.localStorage
		@template = _.template directory.utils.templateLoader.get('feed-page')
		@tweetTemplate = _.template directory.utils.templateLoader.get('tweet-template')
		@facebookTemplate = _.template directory.utils.templateLoader.get('facebook-template')

	render: (eventName) ->
		console.log 'rendering started'
		$(@el).html @template()
		setTimeout =>
			@iscroll = new iScroll $('.scroll', @el)[0], {hScrollbar:false, vScrollbar:false}
			@iscroll.refresh()
		, 100
		@

	facebook: (e) ->
		# First check if we are logged in
		FB.getLoginStatus (res)->
			console.log("checking status", res)
			if res.status != 'connected'
				FB.login(null, {scope:'email, read_stream'}, (loginRes)->
					console.log "logged in", loginRes
				, (loginRes) ->
					console.log("login failed", loginRes)
				)
		, (res) ->
			console.log("failed")
		# get the home screen
		FB.api '/me/home', fields:'', (response)=>
			#response also has paging information
			news = response.data
			console.log 'fetched news', response, news
			@facebookSuccess(news)
		e.preventDefault()

	facebookSuccess: (news) ->
		console.log 'facebook success', news
		$('.networks').hide()
		$('ul').empty()
		for update in news
			do (update) =>
				#console.log 'update', typeof update
				$('ul').append  @facebookTemplate({name:update.from.name, message:update.message})
		setTimeout =>
			console.log 'refresh'
			@iscroll.refresh()
		, 100

	twitter: (e) ->
		# this outputs the twitter timeline for the user
		# check is twitter is available
		#window.plugins.twitter.isTwitterAvailable (r)->
			#console.log('twitter available? ' + r)
			#if r == 1
				#window.plugins.twitter.isTwitterSetup (r)->
					#console.log('twitter configured? ' + r)
					#if r == 1
		@tweets = @storage.getItem('julian')
		if @tweets
			@twitterSuccess @tweets
		else
			window.plugins.twitter.getTWRequest 'statuses/home_timeline.json', {}, (s)=>
				@twitterSuccess(s)
			, (e) =>
				@twitterFailure(e)
		e.preventDefault()

	twitterSuccess: (response) ->
		user ='julian'
		# the value stored in local storage must be a string
		unless @tweets
			@storage.setItem(user, JSON.stringify response)
		else
			response = JSON.parse response
		console.log 'tweets'
		#alert JSON.stringify response, null, ' '
		console.log 'success'
		$('.networks').hide()
		$('ul').empty()
		console.log 'hide networks'
		# TODO should eventually build a model to deal with this
		for tweet in response
			do (tweet) =>
				$('ul').append @tweetTemplate tweet
		$('#log').html JSON.stringify response, null, ' '
		setTimeout =>
			console.log 'refresh'
			@iscroll.refresh()
		, 100

	twitterFailure: (response) ->
		$('#log').html JSON.stringify response

directory.views.SyncPage = class SyncPage extends Backbone.View

	events:
		'click .sync': 'sync',
		'click .reset': 'reset'

	initialize: ->
		_.bindAll @
		@template = _.template directory.utils.templateLoader.get('sync-page')

	render: (eventName) ->
		$(@el).html @template()
		syncUrl = window.localStorage.getItem('syncUrl')
		unless syncUrl
			syncUrl = 'http://employeedirectory.org/api/employees'
		$('#syncUrl', @el).val syncUrl
		@

	sync: ->
		window.localStorage.setItem 'syncUrl', $('#syncUrl').val()
		dao = new directory.dao.EmployeeDAO(directory.db)
		$('#hourglass').show()
		dao.sync (numItems) ->
			$('#hourglass').hide()
			showAlert(numItems + ' items synchronized', 'complete')
			directory.app.searchResults.reset()
		, (errorMessage) ->
			$('#hourglass').hide()
			showAlert(errorMessage, "Error")
		false

	reset: ->
		dao = new directory.dao.EmployeeDAO(directory.db)
		dao.reset ->
			showAlert 'The local database has been reset', 'Reset'
			directory.app.searchResults.reset()
		false


