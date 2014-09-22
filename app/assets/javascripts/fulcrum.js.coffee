$ ->
  $("#add_story").click ->
    window.projectView.newStory()

    # Show chilly bin if it's hidden
    $(".hide_chilly_bin.pressed").click()
    newStoryElement = $("#chilly_bin div.story:last")
    $("#chilly_bin").scrollTo newStoryElement, 100
    return

  # Add close button to flash messages
  $("#messages div").prepend("<a class=\"close\" href=\"#\">×</a>").find("a.close").click ->
    $(this).parent().fadeOut()
    false

  # keycut listener
  $("html").keypress (event) ->
    code = event.which or event.keyCode
    keyChar = String.fromCharCode(code)
    switch code
      when 63 # ? | Should only work without a focused element
        unless $(":focus").length
          if $("#keycut-help").length
            $("#keycut-help").fadeOut ->
              $("#keycut-help").remove()
              return

          else
            new Fulcrum.KeycutView().render()
      when 66 # B | Should only work without a focused element
        $("a.hide_backlog").first().click()  unless $(":focus").length
      when 67 # C | Should only work without a focused element
        $("a.hide_chilly_bin").first().click()  unless $(":focus").length
      when 68 # D | Should only work without a focused element
        $("a.hide_done").first().click()  unless $(":focus").length
      when 80 # P | Should only work without a focused element
        $("a.hide_in_progress").first().click()  unless $(":focus").length
      when 97 # a | Should only work without a focused element
        if not $(":focus").length and window.projectView
          window.projectView.newStory()
          $(".hide_chilly_bin.pressed").first().click()
          newStoryElement = $("#chilly_bin div.story:last")
          $("#chilly_bin").scrollTo newStoryElement, 100
          return false
      when 19 # <cmd> + s
        $(".story.editing").find("#submit").click()
      else
    return

  return


# whatever
