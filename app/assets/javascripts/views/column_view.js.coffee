window.Fulcrum ||= {}

class Fulcrum.ColumnView extends Backbone.View
  template: JST["templates/column"]
  tagName: "td"

  events:
    "click a.toggle-column": "toggle"

  initialize: (options)->
    @name = options.name
    @sortable = options.sortable

  render: ->
    @$el.html @template(
      id: @id
      name: @name
    )
    @setSortable() if @sortable
    this

  toggle: ->
    @$el.toggle()
    @trigger "visibilityChanged"
    return

  # Returns the child div containing the story and iteration elements.
  storyColumn: ->
    @$ ".storycolumn"

  # Append a Backbone.View to this column
  appendView: (view) ->
    @storyColumn().append view.el
    return

  # Adds the sortable behaviour to the column.
  setSortable: ->
    @storyColumn().sortable
      handle: ".story-title"
      opacity: 0.6
      items: ".story:not(.accepted)"
      update: (ev, ui) ->
        ui.item.trigger "sortupdate", ev, ui
        return
    return

  # Returns the current visibility state of the column.
  hidden: ->
    @$el.is ":hidden"
