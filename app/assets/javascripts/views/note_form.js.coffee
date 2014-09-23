window.Fulcrum ||= {}
class Fulcrum.NoteForm extends Fulcrum.FormView
  tagName: "div"
  className: "note_form"

  initialize: ->
    # Supply the model with a reference to it's own view object, so it can
    # remove itself from the page when destroy() gets called.
    @model.view = this
    @id = @el.id = @model.id if @model.id
    return

  events:
    "click input": "saveEdit"

  saveEdit: ->
    @disableForm()
    view = this
    @model.save null,
      success: (model, response) ->
        #view.model.set({editing: false});
      error: (model, response) ->
        json = $.parseJSON(response.responseText)
        view.enableForm()
        model.set errors: json.note.errors
        window.projectView.notice
          title: I18n.t("save error",
            defaultValue: "Save error"
          )
          text: model.errorMessages()
        return

    return

  render: ->
    div = @make("div")
    $(div).append @label("note")
    $(div).append "<br/>"
    $(div).append @textArea("note")
    submit = @make("input",
      id: "note_submit"
      type: "button"
      value: "Add note"
    )
    $(div).append submit
    @$el.html div
    this


  # Makes the note for uneditable during save
  disableForm: ->
    @$("input,textarea").attr "disabled", "disabled"
    @$("input[type=\"button\"]").addClass "saving"
    return

  # Re-enables the note form once save is complete
  enableForm: ->
    @$("input,textarea").removeAttr "disabled"
    @$("input[type=\"button\"]").removeClass "saving"
    return
