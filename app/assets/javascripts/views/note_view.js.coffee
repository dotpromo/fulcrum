window.Fulcrum ||= {}
class Fulcrum.NoteView extends Backbone.View
  template: JST["templates/note"]
  tagName: "div"
  className: "note"
  events:
    "click a.delete-note": "deleteNote"

  render: ->
    @$el.html @template(note: @model)
    this

  deleteNote: ->
    @model.destroy()
    @$el.remove()
    false
