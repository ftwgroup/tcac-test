directory.utils.templateLoader = 
	
	templates: {}

	load: (names, callback) ->
		deferreds = []
		$.each names, (index, name) =>
			deferreds.push $.get 'tpl/' + name + '.html', (data) =>
				@templates[name] = data

		$.when.apply(null, deferreds).done callback

	get: (name) ->
		template = @templates[name]
		console.log @templates
		unless template
			showAlert('Template not loaded', 'Error')
		template

# TODO replace with the coffeescript export command or whatever you do to export a var
window.showAlert = (message, title) ->
	if navigator.notification
		navigator.notification.alert message, null, title, 'OK'
	else
		alert title + ": " + message

