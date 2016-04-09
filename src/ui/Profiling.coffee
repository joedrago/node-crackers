Perf = require 'react-addons-perf'
PubSub = require 'pubsub-js'

PROFILING_KEY = 'J'

# To profile Crackers, simply add this anywhere to App.coffee:
#
# require('./Profiling')
#
# It will allow you to start/stop profiling by pressing PROFILING_KEY (see above).
# Results will be displayed in the Console.

class Profiler
  constructor: ->
    @profiling = false
    @keySubscription = PubSub.subscribe 'key', (msg, event) =>
      @onKeyPress(event)

    console.log "Profiling activated. Use '#{PROFILING_KEY}' to start/stop profiling. Results will be printed here."

  start: ->
    console.log "Profiling started."
    Perf.start()

  stop: ->
    Perf.stop()
    console.log "Profiling stopped. Printing results:"
    @print()

  print: ->
    measurements = Perf.getLastMeasurements()

    console.log "Inclusive timing:"
    Perf.printInclusive(measurements)

    console.log "Exclusive timing:"
    Perf.printExclusive(measurements)

    # console.log "DOM measurements:"
    # Perf.printDOM(measurements)

    console.log "Wasted:"
    Perf.printWasted(measurements)

  toggle: ->
    if not @profiling
      @start()
    else
      @stop()
    @profiling = !@profiling

  onKeyPress: (event) ->
    if event.keyCode == PROFILING_KEY.charCodeAt(0)
      @toggle()

new Profiler()
