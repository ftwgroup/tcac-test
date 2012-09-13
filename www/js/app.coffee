window.directory =
	models: {},
	views: {},
	utils: {},
	dao: {},

Backbone.View.prototype.close = ->
	if @beforeClose
		@beforeClose()

	if @iscoll
		console.log 'destroying iscroll'
		@iscroll.destroy()
		@.iscoll = null

	console.log "View undelegateEvents"
	@undelegateEvents()

# Router definition
directory.Router = class AppRouter extends Backbone.Router

	routes:
		"":											"home",
		"list":									"list",
		"calendar":							"calendar"
		"contact/:id":					"contactDetails",
		"contact/:id/groups":		"groups",
		"feed":									"feed",
		"feed/:network":				"feed",
		"sync":									"synchronize",

	initialize: ->
		_.bindAll @
		#window.localStorage.clear()

		# Keep track of the history of pages (we only store the page URL).
		# Used to identify the direction (left or right) of the sliding transition
		# between pages
		@pageHistory = []

		# Register event listener for back button throughout the app
		$('#content').on 'click', '.header-back-button', (event) ->
			window.history.back()
			false

		# Check whether the browser supports touch events...
		if document.documentElement.hasOwnProperty 'ontouchstart'
			document.addEventListener 'touchmove', (e) ->
				e.preventDefault()
				false

			# ... if yes: register touch event listern to change the "selected" state of the item
			$('#content').on 'touchstart', 'a', (event) =>
				@selectItem event
			$('#content').on 'touchend', 'a', (event) =>
				@deselectItem event
		else
			# ... if not: register mouse events instead
			$('#content').on 'mousedown', 'a', (event) =>
				@selectItem event
			$('#content').on 'mouseup', 'a', (event) =>
				@deselectItem event
		@homePage = new directory.views.HomePage()
		@homePage.render()
		#@searchResults = new directory.models.ContactCollection()
		# this should probably be collection: @searchResults
		#@searchPage = new directory.views.SearchPage model: @searchResults
		#$(@searchPage.el).attr 'id', 'searchPage'

	selectItem: (event) ->
		$(event.target).addClass 'tappable-active'

	deselectItem: (event) ->
		$(event.target).removeClass 'tappable-active'

	home: ->
		console.log 'home'
		@slidePage @homePage

	list: ->
		console.log 'search'
		# TODO this is not consistent with the rest of the api, searchPage renders itself
		@searchResults = new directory.models.ContactCollection()
		# this should probably be collection: @searchResults
		@searchPage = new directory.views.SearchPage model: @searchResults
		$(@searchPage.el).attr 'id', 'searchPage'
		@slidePage @searchPage

	calendar: ->
		@slidePage new directory.views.CalendarPage().render()

	contactDetails: (id) ->
		contact = new directory.models.Contact id:id
		contact.fetch
			success: (data) =>
				@slidePage new directory.views.ContactPage({model:data}).render()

	groups: (id) ->
		contact = directory.models.Contact id:id
		contact.groups.fetch()
		@slidePage new directory.views.GroupsPage({model:contact.groups}).render()

	feed: (network) ->
		# feeds are based off the same information as the base contact page
		unless network
			page = new directory.views.FeedsPage().render()
			console.log 'page rendered', page
			@slidePage page		
		else
			page = new directory.views.FeedsPage().render()
			console.log 'page rendered', page
			@slidePage page		


	synchronize: ->
		@searchResults.reset()
		@slidePage new directory.views.SyncPage().render()

	slidePage: (page) ->
		# if there is no current page (app just started) -> 
		# No transition: Position new page in the view port
		if not @currentPage
			$(page.el).attr 'class', 'page stage-center'
			$('#content').append page.el
			@pageHistory = [window.location.hash]
			@currentPage = page
			return

		if @currentPage != @searchPage
			@currentPage.close()

		# Cleaning up: remove old pages that we moved out of the viewport
		$('.stage-right, .stage-left').not('#searchPage').remove()

		if page == @searchPage
			# Always apply a back (slide from left) transition when we go back to the search page
			slideFrom = 'left'
			$(page.el).attr 'class', 'page stage-left'
			# Reinitialize page history
			@pageHistory = [window.location.hash]
		else if @pageHistory.length > 1 and window.location.hash == @pageHistory[@pageHistory.length-2]
			slideFrom = 'left'
			$(page.el).attr 'class', 'page stage-left'
			@pageHistory.pop()
		else
			slideFrom = 'right'
			$(page.el).attr 'class', 'page stage-right'
			@pageHistory.push window.location.hash

		$('#content').append page.el

		# wait until the new page hase been added to the DOM ...
		setTimeout =>
			# slide out the current page: if new page slides from the right -> 
			# slide current page to the left, and vice verse
			$(@currentPage.el).attr 'class', 'page transition ' + (slideFrom == 'right' ? 'stage-left' : 'stage-right')
			# slide in the new page
			$(page.el).attr 'class', 'page stage-center transition'
			@currentPage = page

$(document).ready ->
	# setup the database. Currently the SQL database layer
	directory.db = window.openDatabase "EmployeeDB", '1.0', 'Employee Demo DB', 200000
	employeeDAO = new directory.dao.EmployeeDAO directory.db
	employeeDAO.initialize ->
		directory.utils.templateLoader.load ['search-page', 'group-page', 'contact-page', 'contact-list-item', 'sync-page', 'feed-page', 'tweet-template', 'home-page', 'calendar-list', 'calendar-page'], ->
			directory.app = new directory.Router()
			Backbone.history.start()


