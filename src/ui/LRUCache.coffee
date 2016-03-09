#
# A doubly linked list-based Least Recently Used (LRU) cache. Will keep most
# recently used items while discarding least recently used items when its limit
# is reached.
#
# Licensed under MIT. Copyright (c) 2010 Rasmus Andersson <http://hunch.se/>
# See README.md for details.
#
# Illustration of the design:
#
#       entry             entry             entry             entry
#       ______            ______            ______            ______
#      | head |.newer => |      |.newer => |      |.newer => | tail |
#      |  A   |          |  B   |          |  C   |          |  D   |
#      |______| <= older.|______| <= older.|______| <= older.|______|
#
#  removed  <--  <--  <--  <--  <--  <--  <--  <--  <--  <--  <--  added
#

# Converted to CoffeeScript by Joe Drago.

class LRUCache
  constructor: (@limit) ->
    @size = 0
    @_keymap = {}

  # Put <value> into the cache associated with <key>. Returns the entry which was
  # removed to make room for the new entry. Otherwise undefined is returned
  # (i.e. if there was enough room already).
  #
  put: (key, value) ->
    entry = { key:key, value:value }
    # Note: No protection agains replacing, and thus orphan entries. By design.
    @_keymap[key] = entry
    if @tail
      # link previous tail to the new tail (entry)
      @tail.newer = entry
      entry.older = @tail
    else
      # we're first in -- yay
      @head = entry

    # add new entry to the end of the linked list -- it's now the freshest entry.
    @tail = entry
    if @size == @limit
      # we hit the limit -- remove the head
      return @shift()
    else
      # increase the size counter
      @size += 1

  # Purge the least recently used (oldest) entry from the cache. Returns the
  # removed entry or undefined if the cache was empty.
  #
  # If you need to perform any form of finalization of purged items, this is a
  # good place to do it. Simply override/replace this function:
  #
  #   var c = new LRUCache(123)
  #   c.shift = function() {
  #     var entry = LRUCache.prototype.shift.call(this)
  #     doSomethingWith(entry)
  #     return entry
  #   }
  #
  shift: ->
    # todo: handle special case when limit == 1
    entry = @head
    if entry
      if @head.newer
        @head = @head.newer
        @head.older = undefined
      else
        @head = undefined

      # Remove last strong reference to <entry> and remove links from the purged
      # entry being returned:
      entry.newer = entry.older = undefined
      # delete is slow, but we need to do this to avoid uncontrollable growth:
      delete @_keymap[entry.key]
    return entry

  # Get and register recent use of <key>. Returns the value associated with <key>
  # or undefined if not in cache.
  #
  get: (key, returnEntry) ->
    # First, find our cache entry
    entry = @_keymap[key]
    if entry == undefined
      # Not cached. Sorry.
      return

    # As <key> was found in the cache, register it as being requested recently
    if entry == @tail
      # Already the most recenlty used entry, so no need to update the list
      if returnEntry
        return entry
      else
        return entry.value

    # HEAD--------------TAIL
    #   <.older   .newer>
    #  <--- add direction --
    #   A  B  C  <D>  E
    if entry.newer
      if entry == @head
        @head = entry.newer
      entry.newer.older = entry.older # C <-- E.

    if entry.older
      entry.older.newer = entry.newer # C. --> E
    entry.newer = undefined # D --x
    entry.older = @tail # D. --> E
    if @tail
      @tail.newer = entry # E. <-- D
    @tail = entry
    if returnEntry
      return entry
    else
      return entry.value

  # ----------------------------------------------------------------------------
  # Following code is optional and can be removed without breaking the core
  # functionality.

  # Check if <key> is in the cache without registering recent use. Feasible if
  # you do not want to chage the state of the cache, but only "peek" at it.
  # Returns the entry associated with <key> if found, or undefined if not found.
  #
  find: (key) ->
    return @_keymap[key]

  # Update the value of entry with <key>. Returns the old value, or undefined if
  # entry was not in the cache.
  #
  set: (key, value) ->
    entry = @get(key, true)
    if entry
      oldvalue = entry.value
      entry.value = value
    else
      oldvalue = @put(key, value)
      if oldvalue
        oldvalue = oldvalue.value
    return oldvalue

  # Remove entry <key> from cache and return its value. Returns undefined if not
  # found.
  #
  remove: (key) ->
    entry = @_keymap[key]
    return if not entry

    delete @_keymap[entry.key] # need to do delete unfortunately
    if entry.newer && entry.older
      # relink the older entry with the newer entry
      entry.older.newer = entry.newer
      entry.newer.older = entry.older
    else if entry.newer
      # remove the link to us
      entry.newer.older = undefined
      # link the newer entry to head
      @head = entry.newer
    else if entry.older
      # remove the link to us
      entry.older.newer = undefined
      # link the newer entry to head
      @tail = entry.older
    else # if(entry.older == undefined && entry.newer == undefined) {
      @head = @tail = undefined

    @size -= 1
    return entry.value

  # Removes all entries
  removeAll: ->
    # This should be safe, as we never expose strong refrences to the outside
    @head = @tail = undefined
    @size = 0
    @_keymap = {}

  # Return an array containing all keys of entries stored in the cache object, in
  # arbitrary order.
  #
  keys: ->
    return Object.keys(@_keymap)

  # Call `fun` for each entry. Starting with the newest entry if `desc` is a true
  # value, otherwise starts with the oldest (head) enrty and moves towards the
  # tail.
  #
  # `fun` is called with 3 arguments in the context `context`:
  #   `fun.call(context, Object key, Object value, LRUCache self)`
  #
  forEach: (fun, context, desc) ->
    if context == true
      desc = true
      context = undefined
    else if typeof context != 'object'
      context = this

    if desc
      entry = @tail
      while entry
        fun.call(context, entry.key, entry.value, this)
        entry = entry.older
    else
      entry = @head
      while entry
        fun.call(context, entry.key, entry.value, this)
        entry = entry.newer

  # Returns a JSON (array) representation
  toJSON: ->
    s = []
    entry = @head
    while entry
      s.push({key:entry.key.toJSON(), value:entry.value.toJSON()})
      entry = entry.newer
    return s

  # Returns a String representation
  toString: ->
    s = ''
    entry = @head
    while entry
      s += String(entry.key)+':'+entry.value
      entry = entry.newer
      if entry
        s += ' < '
    return s

# Export ourselves
module.exports = LRUCache
