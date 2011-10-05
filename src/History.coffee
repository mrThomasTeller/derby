qs = require 'qs'

win = window
winHistory = win.history
winLocation = win.location

History = module.exports = (@_routes, page) ->
  page.history = this
  @_page = page
  return

# TODO: Add support for get & post form submissions

History:: =

  push: (url, render, e) ->
    @_update 'pushState', url, render, e

  replace: (url, render, e) ->
    @_update 'replaceState', url, render, e

  _update: (historyMethod, url, render, e) ->
    # If this is a form submisssion, extract the form data and
    # append it to the url for a get or params.body for a post
    method = 'get'
    if e && e.type is 'submit'
      form = e.target
      obj = {}
      for el in form.elements
        obj[name] = el.value  if name = el.name
      if form.method.toLowerCase() is 'post'
        body = obj
        method = 'post'
      else
        url += '?' + qs.stringify obj

    winHistory[historyMethod] {render}, null, url
    renderRoute url, body, @_page, @_routes[method], 0, e  if render

  _onClickLink: (e) ->
    @push path, true, e  if path = routePath e.target.href

  _onSubmitForm: (e) ->
    form = e.target
    return if !(path = routePath form.action) ||
      form.enctype == 'multipart/form-data'
    @push path, true, e

  _onPop: (e) ->
    # Note that the post body is only sent on the initial reqest
    # and null is sent if the state is later popped
    unless e.state && !e.state.render
      renderRoute winLocation.pathname, null, @_page, @_routes, 0

  back: winHistory.back

  forward: winHistory.forward

  go: winHistory.go


renderRoute = (url, body, page, routes, i, e) ->
  console.log 'requesting', url
  [path, query] = url.split '?'
  while route = routes[i++]
    continue unless match = route.match path
    # Cancel the default action when a route is found to match
    e.preventDefault()  if e

    params = {url, body, query: if query then qs.parse query else {}}
    for {name}, j in route.keys
      params[name] = match[j + 1]
    next = -> renderRoute url, body, page, routes, i
    route.callbacks page, page.model, params, next
    return

  # Update the location if the route can't be handled
  # and it has been cancelled or is not from an event
  win.location = url  unless e

routePath = (url) ->
  # TODO: Ignore skip links

  # Get the pathname if it is on the same domain
  match = /^https?:\/\/([^\/]+)([^#]+)/.exec url
  return match && match[1] == winLocation.host && match[2]
