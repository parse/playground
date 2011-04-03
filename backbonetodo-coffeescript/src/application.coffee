class Todo extends Backbone.Model
	EMPTY: "empty todo..."

	initialize: ->
		@set({"content": @EMPTY}) if not @get("content")

	toggle: ->
		@save( { done: !@get("done") } )

	clear: ->
		@destroy()
		@view.remove()

class TodoList extends Backbone.Collection
		model: Todo
		localStorage: new Store("todos")
		
		done: -> 
			@filter (todo) -> todo.get('done')
		
		remaining: ->
			@without.apply(@, @done())

		nextOrder: ->
			if (!@length) 
				1
			else
				@last().get('order') + 1

		comparator: (todo) ->
			todo.get('order')

Todos = new TodoList

class TodoView extends Backbone.View
		tagName:  "li"
		template: _.template($('#item-template').html())
		events: {
			"click .check"              : "toggleDone",
			"dblclick div.todo-content" : "edit",
			"click span.todo-destroy"   : "clear",
			"keypress .todo-input"      : "updateOnEnter"
		}

		initialize: ->
			_.bindAll(@, 'render', 'close')
			@model.bind('change', @render)
			@model.view = @

		render: ->
			$(@el).html(@template(@model.toJSON()))
			@setContent()
			@

		setContent: ->
			content = @model.get('content')

			@$('.todo-content').text(content)
			this.input = @$('.todo-input')
			@input.bind('blur', @close)
			@input.val(content)

		toggleDone: ->
			@model.toggle()

		edit: ->
			$(@el).addClass("editing")
			@input.focus()

		close: ->
			@model.save({content: @input.val()})
			$(@el).removeClass("editing")

		updateOnEnter: (e) ->
			@close() if e.keyCode == 13

		remove: ->
			$(@el).remove()

		clear: ->
			@model.clear()

class AppView extends Backbone.View
	el: $("#todoapp")
	statsTemplate: _.template($('#stats-template').html())
	events: {
		"keypress #new-todo":  "createOnEnter",
		"keyup #new-todo":     "showTooltip",
		"click .todo-clear a": "clearCompleted"
	}

	initialize: ->
		_.bindAll(@, 'addOne', 'addAll', 'render')

		@input = @$("#new-todo")

		Todos.bind('add',     @addOne)
		Todos.bind('refresh', @addAll)
		Todos.bind('all',     @render)

		Todos.fetch()

	render: ->
		done = Todos.done().length
		@$('#todo-stats').html(@statsTemplate({
			total:      Todos.length,
			done:       Todos.done().length,
			remaining:  Todos.remaining().length
		}))

	addOne: (todo) ->
		view = new TodoView({model: todo})
		@$("#todo-list").append(view.render().el)

	addAll: ->
		Todos.each(@addOne)

	newAttributes: -> 
		{
			content: @input.val(),
			order:   Todos.nextOrder(),
			done:    false
		}

	createOnEnter: (e) ->
		return if e.keyCode isnt 13
		
		Todos.create(@newAttributes())
		@input.val('')

	clearCompleted: ->
		_.each( Todos.done(), ((todo) => todo.save() ))

		false
    
	showTooltip: (e) ->
		tooltip = @$(".ui-tooltip-top")
		val = @input.val()
		tooltip.fadeOut()
		
		if (@tooltipTimeout) 
			clearTimeout(@tooltipTimeout)
			
		return if val is '' or val is @input.attr('placeholder')
			
		show = ->
			tooltip.show().fadeIn()

		this.tooltipTimeout = _.delay(show, 1000)

@app = new AppView;