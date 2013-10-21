# Used to keep elements in the sidebar always visible when the page is scrolled.
#= require jquery/jquery.sticky

$ ->
  if isOnPage 'spaces', 'index'

    format = (space) ->
      "<img class='logo' src='" + space.logo_image_url + "'/> " + space.name

    $("#space_filter_text").select2
      minimumInputLength: 1
      placeholder: I18n.t('search.space.dots')
      width: '250'
      ajax:
        url: '/spaces/select'
        dataType: 'json'
        data: (term, page) ->
          q: term
        results: (data, page) ->
          results: data

    # buttons to select the type of filter
    #$("#show-spaces-all").on "click", ->
    #  $("#content-middle .not-my-space").show()
    #$("#show-spaces-mine").on "click", ->
    #  $("#content-middle .not-my-space").hide()
    #  $("#content-middle .my-space").show()
    #$("#show-spaces-filter").on "click", ->
    #  $("#space-filter-text").keyup()
    #  $("#space-filter-text").focus()

    # filter the spaces being shown when the user types
    #$("#space-filter-text").keyup ->
    #  $("#show-spaces_filter").attr "checked", true
    #  filter_text = $(this).val().toLowerCase()
    #  filter_spaces filter_text

    # if the filter input has a text, filter the spaces
    #unless $("#space-filter-text").val() is ""
    #  $("#space-filter-text").keyup()
    #  $("#space-filter-text").focus()

    # hovering an space shows its description in the sidebar
    $(".space-item").hover ->

      # hide all descriptions and shows the selected
      hovered = "div#" + $(this).attr("name") + "-description"
      $("#space-description-wrapper div.content-block-middle").hide()
      $(hovered).show()

      # remove all 'selected' classes and adds only to the selected div
      $(".space-item.selected").removeClass("selected")
      $(this).addClass("selected")

      # updates the position of the description div
      $("#space-description-wrapper").sticky("update")

    # move the space description in the sidebar to be always in
    # the visible space of the page when the page is scrolled
    $("#space-description-wrapper").sticky
      topSpacing: 20
      bottomSpacing: 250

# function that filters the spaces being shown
#filter_spaces = (filter_text) ->
#  $(".space-item").each ->
#    if $(this).attr("name").toLowerCase().search(filter_text) >= 0
#      $(this).show()
#    else
#      $(this).hide()
