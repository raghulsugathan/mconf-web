# http://dense13.com/blog/2009/05/03/converting-string-to-slug-javascript/
stringToSlug = (str) ->
  str = str.replace(/^\s+|\s+$/g, '')
  str = str.toLowerCase()

  # remove accents, swap ñ for n, etc
  from = "ãàáäâẽèéëêĩìíïîõòóöôũùúüûñçć·/_,:;!"
  to   = "aaaaaeeeeeiiiiiooooouuuuuncc-------"
  for i in [0..from.length]
    str = str.replace(new RegExp(from.charAt(i), 'g'), to.charAt(i))

  str.replace(/[^a-z0-9 -]/g, '') # remove invalid chars
     .replace(/\s+/g, '-') # collapse whitespace and replace by -
     .replace(/-+/g, '-') # collapse dashes

class mconf.SignupForm
  @setup: ->
    $fullname = $("#user__full_name")
    $username = $("#user_username")
    $username.attr "value", stringToSlug($fullname.val())
    $fullname.on "input keyup", () ->
      $username.attr "value", stringToSlug($fullname.val())

# Dynamic search for institutions
id = '#user_institution_name'
url = '/institutions/select.json'

$(id).tokenInput url,
  crossDomain: false
  theme: 'facebook'
  tokenLimit: 1
  # hintText: $('#hidden-data #hint').value
  # noResultsText: $('#hidden-data #no-results').value
  # searchingText: $('#hidden-data #searching').value

