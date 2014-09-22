window.Fulcrum ||= {}

class Fulcrum.NoteCollection extends Backbone.Collection
  model: Fulcrum.Note

  url: ->
    @story.url() + "/notes"

  saved: ->
    @reject (note) ->
      note.isNew()
