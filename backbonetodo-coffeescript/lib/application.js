(function() {
  var AppView, Todo, TodoList, TodoView, Todos;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Todo = (function() {
    function Todo() {
      Todo.__super__.constructor.apply(this, arguments);
    }
    __extends(Todo, Backbone.Model);
    Todo.prototype.EMPTY = "empty todo...";
    Todo.prototype.initialize = function() {
      if (!this.get("content")) {
        return this.set({
          "content": this.EMPTY
        });
      }
    };
    Todo.prototype.toggle = function() {
      return this.save({
        done: !this.get("done")
      });
    };
    Todo.prototype.clear = function() {
      this.destroy();
      return this.view.remove();
    };
    return Todo;
  })();
  TodoList = (function() {
    function TodoList() {
      TodoList.__super__.constructor.apply(this, arguments);
    }
    __extends(TodoList, Backbone.Collection);
    TodoList.prototype.model = Todo;
    TodoList.prototype.localStorage = new Store("todos");
    TodoList.prototype.done = function() {
      return this.filter(function(todo) {
        return todo.get('done');
      });
    };
    TodoList.prototype.remaining = function() {
      return this.without.apply(this, this.done());
    };
    TodoList.prototype.nextOrder = function() {
      if (!this.length) {
        return 1;
      } else {
        return this.last().get('order') + 1;
      }
    };
    TodoList.prototype.comparator = function(todo) {
      return todo.get('order');
    };
    return TodoList;
  })();
  Todos = new TodoList;
  TodoView = (function() {
    function TodoView() {
      TodoView.__super__.constructor.apply(this, arguments);
    }
    __extends(TodoView, Backbone.View);
    TodoView.prototype.tagName = "li";
    TodoView.prototype.template = _.template($('#item-template').html());
    TodoView.prototype.events = {
      "click .check": "toggleDone",
      "dblclick div.todo-content": "edit",
      "click span.todo-destroy": "clear",
      "keypress .todo-input": "updateOnEnter"
    };
    TodoView.prototype.initialize = function() {
      _.bindAll(this, 'render', 'close');
      this.model.bind('change', this.render);
      return this.model.view = this;
    };
    TodoView.prototype.render = function() {
      $(this.el).html(this.template(this.model.toJSON()));
      this.setContent();
      return this;
    };
    TodoView.prototype.setContent = function() {
      var content;
      content = this.model.get('content');
      this.$('.todo-content').text(content);
      this.input = this.$('.todo-input');
      this.input.bind('blur', this.close);
      return this.input.val(content);
    };
    TodoView.prototype.toggleDone = function() {
      return this.model.toggle();
    };
    TodoView.prototype.edit = function() {
      $(this.el).addClass("editing");
      return this.input.focus();
    };
    TodoView.prototype.close = function() {
      this.model.save({
        content: this.input.val()
      });
      return $(this.el).removeClass("editing");
    };
    TodoView.prototype.updateOnEnter = function(e) {
      if (e.keyCode === 13) {
        return this.close();
      }
    };
    TodoView.prototype.remove = function() {
      return $(this.el).remove();
    };
    TodoView.prototype.clear = function() {
      return this.model.clear();
    };
    return TodoView;
  })();
  AppView = (function() {
    function AppView() {
      AppView.__super__.constructor.apply(this, arguments);
    }
    __extends(AppView, Backbone.View);
    AppView.prototype.el = $("#todoapp");
    AppView.prototype.statsTemplate = _.template($('#stats-template').html());
    AppView.prototype.events = {
      "keypress #new-todo": "createOnEnter",
      "keyup #new-todo": "showTooltip",
      "click .todo-clear a": "clearCompleted"
    };
    AppView.prototype.initialize = function() {
      _.bindAll(this, 'addOne', 'addAll', 'render');
      this.input = this.$("#new-todo");
      Todos.bind('add', this.addOne);
      Todos.bind('refresh', this.addAll);
      Todos.bind('all', this.render);
      return Todos.fetch();
    };
    AppView.prototype.render = function() {
      var done;
      done = Todos.done().length;
      return this.$('#todo-stats').html(this.statsTemplate({
        total: Todos.length,
        done: Todos.done().length,
        remaining: Todos.remaining().length
      }));
    };
    AppView.prototype.addOne = function(todo) {
      var view;
      view = new TodoView({
        model: todo
      });
      return this.$("#todo-list").append(view.render().el);
    };
    AppView.prototype.addAll = function() {
      return Todos.each(this.addOne);
    };
    AppView.prototype.newAttributes = function() {
      return {
        content: this.input.val(),
        order: Todos.nextOrder(),
        done: false
      };
    };
    AppView.prototype.createOnEnter = function(e) {
      if (e.keyCode !== 13) {
        return;
      }
      Todos.create(this.newAttributes());
      return this.input.val('');
    };
    AppView.prototype.clearCompleted = function() {
      _.each(Todos.done(), (__bind(function(todo) {
        return todo.save();
      }, this)));
      return false;
    };
    AppView.prototype.showTooltip = function(e) {
      var show, tooltip, val;
      tooltip = this.$(".ui-tooltip-top");
      val = this.input.val();
      tooltip.fadeOut();
      if (this.tooltipTimeout) {
        clearTimeout(this.tooltipTimeout);
      }
      if (val === '' || val === this.input.attr('placeholder')) {
        return;
      }
      show = function() {
        return tooltip.show().fadeIn();
      };
      return this.tooltipTimeout = _.delay(show, 1000);
    };
    return AppView;
  })();
  this.app = new AppView;
}).call(this);
