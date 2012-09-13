# The contact Model
directory.models.Contact = class Contact extends Backbone.Model

	dao: directory.dao.EmployeeDAO

	initialize: ->
		_.bindAll @
		# TODO change this to reflect that we are not an employe directory
		@groups = new directory.models.ContactCollection()
		@groups.managerId = @id
		# everytime we get a new model grab the social network information
		#@on 'change', @getSocialData, @

	getSocialData: ->
		console.log('getting social data')

directory.models.ContactCollection = class ContactCollection extends Backbone.Collection

	dao: directory.dao.EmployeeDao

	model: directory.models.Contact

	initialize: ->
		_.bindAll @

	findByName: (key) ->
		# TODO probably don't need a new connection everytime
		employeeDao = new directory.dao.EmployeeDAO(directory.db)
		employeeDao.findByName key, (data) =>
			@reset(data)