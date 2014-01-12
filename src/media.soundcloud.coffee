debug = window.console.debug.bind console
# videojs = require "video.js"
# URI = require "URIjs"
###
Documentation can be generated using {https://github.com/coffeedoc/codo Codo}
###

###
Add a script to head with the given @scriptUrl
###
addScriptTag = (scriptUrl)->
	debug "adding script #{scriptUrl}"
	tag = document.createElement 'script'
	tag.src = scriptUrl
	firstScriptTag = document.getElementsByTagName('script')[0]
	firstScriptTag.parentNode.insertBefore tag, firstScriptTag

###
Soundcloud Media Controller - Wrapper for Soundcloud Media API
API SC.Widget documentation: http://developers.soundcloud.com/docs/api/html5-widget
API Track documentation: http://developers.soundcloud.com/docs/api/reference#tracks
@param [videojs.Player] player
@param [Object] options soundcloudClientId is mandatory!
@param [Function] ready
###
videojs.Soundcloud = videojs.MediaTechController.extend
	init: (player, options, ready)->
		debug "initializing Soundcloud tech"

		# Define which features we provide
		@features.fullscreenResize = true
		@features.volumeControl = true
		videojs.MediaTechController.call(@, player, options, ready)

		@player_ = player

		@clientId = @player_.options().soundcloudClientId
		@soundcloudSource = ""
		@soundcloudSource = options.source.src || "" if options.source

		# Create the iframe for the soundcloud API
		@scWidgetId = "#{@player_.id()}_soundcloud_api_#{Date.now()}"
		@scWidgetElement = videojs.Component::createEl 'iframe',
			id: @scWidgetId
			className: 'vjs-tech'
			scrolling: 'no'
			marginWidth: 0
			marginHeight: 0
			frameBorder: 0
			webkitAllowFullScreen: "true"
			mozallowfullscreen: "true"
			allowFullScreen: "true"
			style: "visibility: hidden;"
			src: "https://w.soundcloud.com/player/?url=#{@soundcloudSource}"

		@el().appendChild @scWidgetElement
		@el().classList.add "backgroundContainer"
		debug "added widget div with src: #{@scWidgetElement.src}"

		# Make autoplay work for iOS
		if @player_.options().autoplay
			@playOnReady = true

		debug "loading soundcloud"
		@loadSoundcloud()

###
Set up everything to use soundcloud's streaming API
###
videojs.Soundcloud::onApiReady = ->
	debug "onApiReady (SC exists)"

	if not @apiInitialized
		SC.initialize client_id: @clientId
		@apiInitialized = true

	@initWidget()

###
Destruct the tech and it's DOM elements
###
videojs.Soundcloud::dispose = ->
	debug "dispose"
	if @scWidgetElement
		@scWidgetElement.remove()
		debug "Removed widget Element"
		debug @scWidgetElement
	@el().classList.remove "backgroundContainer"
	@el().style.backgroundImage = ""
	debug "removed CSS"
	delete @soundcloudPlayer if @soundcloudPlayer

videojs.Soundcloud::load = ->
	debug "loading"
	@loadSoundcloud()

videojs.Soundcloud.prototype.src = (src)->
	debug "load a new source(#{src})"
	@soundcloudPlayer.load src, callback: =>
		@onReady()

videojs.Soundcloud::updatePoster = ->
	try
		# Get artwork for the sound
		@soundcloudPlayer.getSounds (sounds) =>
			debug "got sounds"
			return if sounds.length != 1

			sound = sounds[0]
			return if  not sound.artwork_url
			debug "Setting poster to #{sound.artwork_url}"
			posterUrl = sound.artwork_url
			@el().style.backgroundImage = "url('#{posterUrl}')"
			#@player_.poster(posterUrl)
	catch e
		debug "Could not update poster"

videojs.Soundcloud::play = ->
	if @isReady_
		debug "play"
		@soundcloudPlayer.play()
	else
		debug "to play on ready"
		# We will play it when the API will be ready
		@playOnReady = true

###
Toggle the playstate between playing and paused
###
videojs.Soundcloud::toggle = ->
	debug "toggle"
	# We used @player_ to trigger events for changing the display
	if @player_.paused()
		@player_.play()
	else
		@player_.pause()

videojs.Soundcloud::pause = ->
	debug "pause"
	@soundcloudPlayer.pause()
videojs.Soundcloud::paused = ->
	debug "paused: #{@paused_}"
	@paused_

###
@return track time in seconds
###
videojs.Soundcloud::currentTime = ->
	debug "currentTime #{@durationMilliseconds * @playPercentageDecimal / 1000}"
	@durationMilliseconds * @playPercentageDecimal / 1000

videojs.Soundcloud::setCurrentTime = (seconds)->
	debug "setCurrentTime"
	@soundcloudPlayer.seekTo(seconds*1000)
	@player_.trigger('timeupdate')

###
@return total length of track in seconds
###
videojs.Soundcloud::duration = ->
	#debug "duration: #{@durationMilliseconds / 1000}"
	@durationMilliseconds / 1000

# TODO Fix buffer-range calculations
videojs.Soundcloud::buffered = ->
	timePassed = @duration() * @loadPercentageDecimal
	debug "buffered #{timePassed}"
	videojs.createTimeRange 0, timePassed

videojs.Soundcloud::volume = ->
	debug "volume: #{@volumeVal}"
	@volumeVal

videojs.Soundcloud::setVolume = (percentAsDecimal)->
	debug "setVolume(#{percentAsDecimal}) from #{@volumeVal}"
	if percentAsDecimal != @volumeVal
		@volumeVal = percentAsDecimal
		@soundcloudPlayer.setVolume(@volumeVal * 100)
		debug "volume has been set"
		@player_.trigger 'volumechange'

videojs.Soundcloud::muted = ->
	debug "muted: #{@volumeVal == 0}"
	@volumeVal == 0

###
Soundcloud doesn't do muting so we need to handle that.

A possible pitfall is when this is called with true and the volume has been changed elsewhere.
We will use @unmutedVolumeVal

@param {Boolean}
###
videojs.Soundcloud::setMuted = (muted)->
	debug "setMuted(#{muted})"
	if muted
		@unmuteVolume = @volumeVal
		@setVolume 0
	else
		@setVolume @unmuteVolume


###
Take a wild guess ;)
###
videojs.Soundcloud.isSupported = ->
	debug "isSupported: #{true}"
	return true

###
Fullscreen of audio is just enlarging making the container fullscreen and using it's poster as a placeholder.
###
videojs.Soundcloud::supportsFullScreen = ()->
	debug "we support fullscreen!"
	return true

###
Fullscreen of audio is just enlarging making the container fullscreen and using it's poster as a placeholder.
###
videojs.Soundcloud::enterFullScreen = ()->
	debug "enterfullscreen"
	@scWidgetElement.webkitEnterFullScreen()

###
We return the player's container to it's normal (non-fullscreen) state.
###
videojs.Soundcloud::exitFullScreen = ->
	debug "EXITfullscreen"
	@scWidgetElement.webkitExitFullScreen()

###
Simple URI host check of the given url to see if it's really a soundcloud url
@param url {String}
###
videojs.Soundcloud::isSoundcloudUrl = (url)->
	uri = new URI url

	switch uri.hostname()
		when "www.soundcloud.com", "soundcloud.com"
			debug "Can play '#{url}'"
			return true
		else
			debug "Cannot player #{url}"
			return false

###
We expect "audio/soundcloud" or a src containing soundcloud
###
videojs.Soundcloud::canPlaySource = videojs.Soundcloud.canPlaySource = (source)->
	if typeof source == "string"
		return videojs.Soundcloud::isSoundcloudUrl source
	else
		debug "Can play source?"
		debug source
		ret = (source.type == 'audio/soundcloud') or videojs.Soundcloud::isSoundcloudUrl(source.src)
		debug ret
		return ret


###
Take care of loading the Soundcloud API
###
videojs.Soundcloud::loadSoundcloud = ->
	debug "loadSoundcloud"

	# Prepare everything for playing
	if videojs.Soundcloud.apiReady and not @soundcloudPlayer
		debug "simply initializing the widget"
		@initWidget()
	else
		# Load the Soundcloud API if it is the first Soundcloud video
		if not videojs.Soundcloud.apiLoading

			# Initiate the soundcloud tech once the API is ready
			checkSoundcloudApiReady = =>
				if typeof window.SC != "undefined"
					videojs.Soundcloud.apiReady = true
					window.clearInterval videojs.Soundcloud.intervalId
					@onApiReady()
					debug "cleared interval"
			addScriptTag "https://w.soundcloud.com/player/api.js"
			addScriptTag "https://connect.soundcloud.com/sdk.js"
			videojs.Soundcloud.apiLoading = true
			videojs.Soundcloud.intervalId = window.setInterval checkSoundcloudApiReady, 10

###
It should initialize a soundcloud Widget, which will be our player
and which will react to events.
###
videojs.Soundcloud::initWidget = ->
	debug "Initializing the widget"

	@soundcloudPlayer = SC.Widget @scWidgetElement
	debug "created widget"
	@soundcloudPlayer.bind SC.Widget.Events.READY, =>
		@onReady()
	debug "attempted to bind READY"
	@soundcloudPlayer.bind SC.Widget.Events.PLAY_PROGRESS, (eventData)=>
		@onPlayProgress eventData.relativePosition

	@soundcloudPlayer.bind SC.Widget.Events.LOAD_PROGRESS, (eventData) =>
		debug "loading"
		@onLoadProgress eventData.loadedProgress

	@soundcloudPlayer.bind SC.Widget.Events.ERROR, (error)=>
		@onError error

	@soundcloudPlayer.bind SC.Widget.Events.PLAY, =>
		@onPlay()

	@soundcloudPlayer.bind SC.Widget.Events.PAUSE, =>
		@onPause()

	@soundcloudPlayer.bind SC.Widget.Events.FINISH, =>
		@onFinished()


###
Callback for soundcloud's READY event.
###
videojs.Soundcloud::onReady = ->
	debug "onReady"

	@volumeVal = 0
	@durationMilliseconds = 1
	@loadPercentageDecimal = 0
	@playPercentageDecimal = 0
	@paused_ = true

	# Preparing to handle muting
	@soundcloudPlayer.getVolume (volume) =>
		@unmuteVolume = volume / 100
		@setVolume @unmuteVolume


	try
		# It's async and won't change so let's do this now
		@soundcloudPlayer.getDuration (duration) =>
			@durationMilliseconds = duration
			@player_.trigger 'durationchange'
			@player_.trigger "canplay"
	catch e
		debug "could not get the duration"


	@updatePoster()

	# Trigger buffering
	#@soundcloudPlayer.play()
	#@soundcloudPlayer.pause()

	@triggerReady()
	# Play right away if we clicked before ready
	try
		@soundcloudPlayer.play() if @playOnReady
	catch e
		debug "could not play onready"

	debug "finished onReady"


###
Callback for Soundcloud's PLAY_PROGRESS event
It should keep track of how much has been played.
@param {Decimal= playPercentageDecimal} [0...1] How much has been played  of the sound in decimal from [0...1]
###
videojs.Soundcloud::onPlayProgress = (@playPercentageDecimal)->
	debug "onPlayProgress"
	@player_.trigger "playing"

###
Callback for Soundcloud's LOAD_PROGRESS event.
It should keep track of how much has been buffered/loaded.
@param {Decimal= loadPercentageDecimal} How much has been buffered/loaded of the sound in decimal from [0...1]
###
videojs.Soundcloud::onLoadProgress = (@loadPercentageDecimal)->
	debug "onLoadProgress: #{@loadPercentageDecimal}"
	@player_.trigger "timeupdate"

###
Callback for Soundcloud's PLAY event.
It should keep track of the player's paused and playing status.
###
videojs.Soundcloud::onPlay = ->
	debug "onPlay"
	@paused_ = false
	@playing = not @paused_
	@player_.trigger "play"

###
Callback for Soundcloud's PAUSE event.
It should keep track of the player's paused and playing status.
###
videojs.Soundcloud::onPause = ->
	debug "onPause"
	@paused_ = true
	@playing = not @paused_
	@player_.trigger "pause"

###
Callback for Soundcloud's FINISHED event.
It should keep track of the player's paused and playing status.
###
videojs.Soundcloud::onFinished = ->
	@paused_ = false # TODO what does videojs expect here?
	@playing = not @paused_
	@player_.trigger "ended"

###
Callback for Soundcloud's ERROR event.
Sadly soundlcoud doesn't send any information on what happened when using the widget API --> no error message.
###
videojs.Soundcloud::onError = ->
	@player_.error = "Soundcloud error"
	@player_.trigger('error')