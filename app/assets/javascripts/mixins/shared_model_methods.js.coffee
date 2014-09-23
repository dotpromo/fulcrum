window.Fulcrum ||= {}
Fulcrum.SharedModelMethods =

  # Returns the translated name of an attribute
  humanAttributeName: (attribute) ->
    attribute = attribute.replace(/_id$/, "")
    I18n.t attribute,
      scope: @i18nScope

  errorMessages: ->
    _.map(@get("errors"), (errors, field) ->
      _.map(errors, (error) ->
        field + " " + error
      ).join ", "
    ).join ", "

  hasErrors: ->
    typeof @get("errors") isnt "undefined"

  errorsOn: (field) ->
    return false  unless @hasErrors()
    typeof @get("errors")[field] isnt "undefined"
