window.Fulcrum ||= {}

class Fulcrum.ColumnVisibilityButtonView extends Backbone.View
  tagName: "a"

  attributes:
    href: "#"

  events:
    click: "toggle"

  initialize: (options) ->
    _.bindAll this, "setClassName"
    @columnView = options.columnView
    @$el.attr "class", "hide_" + @columnView.id
    @listenTo @columnView, 'visibilityChanged', @setClassName
    return

  render: ->
    @$el.html @columnView.name
    this

  # Delegates to toggle() on the associated ColumnView
  toggle: ->
    @columnView.toggle()
    return

  setClassName: ->
    if @columnView.hidden()
      @$el.addClass "pressed"
    else
      @$el.removeClass "pressed"
    return
