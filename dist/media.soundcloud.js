/*! video.js-soundcloud v2.0.0-unstable_13-03-2017 */
var Soundcloud, SoundcloudSourceHandler, Tech, addScriptTag, extend = function(a, b) {
    function c() {
        this.constructor = a;
    }
    for (var d in b) hasProp.call(b, d) && (a[d] = b[d]);
    return c.prototype = b.prototype, a.prototype = new c(), a.__super__ = b.prototype, 
    a;
}, hasProp = {}.hasOwnProperty;

Tech = window.videojs.getComponent("Tech"), !window.DEBUG && window.console && (window.console.debug = function() {}), 
addScriptTag = function(a) {
    var b, c;
    return c = document.createElement("script"), c.src = a, b = document.getElementsByTagName("head")[0], 
    b.parentNode.appendChild(c);
}, Soundcloud = function(a) {
    function b(a, c) {
        b.__super__.constructor.call(this, a, c), this.volumeVal = 0, this.durationMilliseconds = 1, 
        this.currentPositionSeconds = 0, this.loadPercentageDecimal = 0, this.paused_ = !0, 
        this.poster_ = null, this.soundcloudSource = null, "string" == typeof a.source ? this.soundcloudSource = a.source : "object" == typeof a.source && (this.soundcloudSource = a.source.src), 
        this.ready(function(a) {
            return function() {
                return a.trigger("loadstart");
            };
        }(this)), this.scWidgetElement.id = this.scWidgetId = "soundcloud_api_" + Date.now(), 
        this.scWidgetElement.src = "" + b.URL_PREFIX + this.soundcloudSource, this.loadSoundcloud();
    }
    return extend(b, a), b.URL_PREFIX = "https://w.soundcloud.com/player/?url=", b.prototype.createEl = function() {
        return this.scWidgetElement = b.__super__.createEl.call(this, "iframe", {
            scrolling: "no",
            marginWidth: 0,
            marginHeight: 0,
            frameBorder: 0,
            webkitAllowFullScreen: "true",
            mozallowfullscreen: "true",
            allowFullScreen: "true"
        }), this.scWidgetElement.style.visibility = "hidden", this.scWidgetElement.style.display = "none", 
        this.scWidgetElement;
    }, b;
}(Tech), Soundcloud.prototype.dispose = function() {
    if (this.scWidgetElement && (this.scWidgetElement.parentNode.removeChild(this.scWidgetElement), 
    delete this.scWidgetElement), this.soundcloudPlayer) return delete this.soundcloudPlayer;
}, Soundcloud.prototype.load = function() {
    return this.loadSoundcloud();
}, Soundcloud.prototype.src = function(a) {
    return a ? this.soundcloudPlayer.load(a, {
        callback: function(b) {
            return function() {
                return b.soundcloudSource = a, b.ready_ || b.onReady(), b.trigger("loadstart");
            };
        }(this)
    }) : this.soundcloudSource;
}, Soundcloud.prototype.currentSrc = function() {
    return this.src();
}, Soundcloud.prototype.poster = function() {
    return this.poster_;
}, Soundcloud.prototype.updatePoster = function() {
    try {
        return this.soundcloudPlayer.getCurrentSound(function(a) {
            return function(b) {
                var c;
                if (b && b.artwork_url) return c = b.artwork_url.replace("large.jpg", "t500x500.jpg"), 
                a.poster_ = c, a.trigger("posterchange");
            };
        }(this));
    } catch (a) {
        return void a;
    }
}, Soundcloud.prototype.play = function() {
    return this.isReady_ ? this.soundcloudPlayer.play() : this.playOnReady = !0;
}, Soundcloud.prototype.toggle = function() {
    return this.player_.paused() ? this.player_.play() : this.player_.pause();
}, Soundcloud.prototype.pause = function() {
    return this.soundcloudPlayer.pause();
}, Soundcloud.prototype.paused = function() {
    return this.paused_;
}, Soundcloud.prototype.currentTime = function() {
    return this.currentPositionSeconds;
}, Soundcloud.prototype.setCurrentTime = function(a) {
    return this.soundcloudPlayer.seekTo(1e3 * a), this.player_.trigger("seeking");
}, Soundcloud.prototype.duration = function() {
    return this.durationMilliseconds / 1e3;
}, Soundcloud.prototype.buffered = function() {
    var a;
    return a = this.duration() * this.loadPercentageDecimal, videojs.createTimeRange(0, a);
}, Soundcloud.prototype.volume = function() {
    return this.volumeVal;
}, Soundcloud.prototype.setVolume = function(a) {
    if (a !== this.volumeVal) return this.volumeVal = a, this.soundcloudPlayer.setVolume(this.volumeVal), 
    this.player_.trigger("volumechange");
}, Soundcloud.prototype.muted = function() {
    return 0 === this.volumeVal;
}, Soundcloud.prototype.setMuted = function(a) {
    return a ? (this.unmuteVolume = this.volumeVal, this.setVolume(0)) : this.setVolume(this.unmuteVolume);
}, Soundcloud.isSupported = function() {
    return !0;
}, Soundcloud.prototype.supportsFullScreen = function() {
    return !0;
}, Soundcloud.prototype.enterFullScreen = function() {
    return this.scWidgetElement.webkitEnterFullScreen();
}, Soundcloud.prototype.exitFullScreen = function() {
    return this.scWidgetElement.webkitExitFullScreen();
}, Soundcloud.prototype.loadSoundcloud = function() {
    var a;
    return Soundcloud.apiReady && !this.soundcloudPlayer ? setTimeout(function(a) {
        return function() {
            return a.initWidget();
        };
    }(this), 1) : Soundcloud.apiLoading ? void 0 : (a = function(a) {
        return function() {
            if (void 0 !== window.SC) return Soundcloud.apiReady = !0, window.clearInterval(Soundcloud.intervalId), 
            void a.initWidget();
        };
    }(this), addScriptTag("https://w.soundcloud.com/player/api.js"), Soundcloud.apiLoading = !0, 
    Soundcloud.intervalId = window.setInterval(a, 10));
}, Soundcloud.prototype.initWidget = function() {
    if (this.soundcloudPlayer = SC.Widget(this.el_), this.soundcloudPlayer.bind(SC.Widget.Events.READY, function(a) {
        return function() {
            return a.onReady();
        };
    }(this)), this.soundcloudPlayer.bind(SC.Widget.Events.PLAY_PROGRESS, function(a) {
        return function(b) {
            return a.onPlayProgress(b.relativePosition);
        };
    }(this)), this.soundcloudPlayer.bind(SC.Widget.Events.LOAD_PROGRESS, function(a) {
        return function(b) {
            return a.onLoadProgress(b.loadedProgress);
        };
    }(this)), this.soundcloudPlayer.bind(SC.Widget.Events.ERROR, function(a) {
        return function() {
            return a.onError();
        };
    }(this)), this.soundcloudPlayer.bind(SC.Widget.Events.PLAY, function(a) {
        return function() {
            return a.onPlay();
        };
    }(this)), this.soundcloudPlayer.bind(SC.Widget.Events.PAUSE, function(a) {
        return function() {
            return a.onPause();
        };
    }(this)), this.soundcloudPlayer.bind(SC.Widget.Events.FINISH, function(a) {
        return function() {
            return a.onFinished();
        };
    }(this)), this.soundcloudPlayer.bind(SC.Widget.Events.SEEK, function(a) {
        return function(b) {
            return a.onSeek(b.currentPosition);
        };
    }(this)), !this.soundcloudSource) return this.triggerReady();
}, Soundcloud.prototype.onReady = function() {
    this.soundcloudPlayer.getVolume(function(a) {
        return function(b) {
            return a.unmuteVolume = b, a.setVolume(a.unmuteVolume);
        };
    }(this));
    try {
        this.soundcloudPlayer.getDuration(function(a) {
            return function(b) {
                return a.durationMilliseconds = b, a.player_.trigger("durationchange"), a.player_.trigger("canplay");
            };
        }(this));
    } catch (a) {
        a;
    }
    return this.updatePoster(), this.triggerReady();
}, Soundcloud.prototype.onPlayProgress = function(a) {
    return this.currentPositionSeconds = this.durationMilliseconds * a / 1e3, this.player_.trigger("playing");
}, Soundcloud.prototype.onLoadProgress = function(a) {
    return this.loadPercentageDecimal = a, this.player_.trigger("timeupdate");
}, Soundcloud.prototype.onSeek = function(a) {
    return this.currentPositionSeconds = a / 1e3, this.player_.trigger("seeked");
}, Soundcloud.prototype.onPlay = function() {
    return this.paused_ = !1, this.playing = !this.paused_, this.player_.trigger("play");
}, Soundcloud.prototype.onPause = function() {
    return this.paused_ = !0, this.playing = !this.paused_, this.player_.trigger("pause");
}, Soundcloud.prototype.onFinished = function() {
    return this.paused_ = !1, this.playing = !this.paused_, this.player_.trigger("ended");
}, Soundcloud.prototype.onError = function() {
    return this.player_.error("There was a soundcloud error. Check the view.");
}, Soundcloud.Events = [ "loadstart", "error", "canplay", "playing", "waiting", "seeking", "seeked", "ended", "durationchange", "timeupdate", "progress", "play", "pause", "volumechange" ], 
SoundcloudSourceHandler = function() {
    function a() {}
    return a.isSoundcloudUrl = function(a) {
        return /^(https?:\/\/)?(www.|api.)?soundcloud.com\/./i.test(a);
    }, a.canPlayType = function(a) {
        return "audio/soundcloud" === a ? "probably" : "";
    }, a.canPlaySource = function(a, b) {
        return this.canPlayType(a.type) || this.isSoundcloudUrl(a.src || a) ? "probably" : "";
    }, a.canHandleSource = function(a, b) {
        return this.canPlaySource(a, b);
    }, a.handleSource = function(a, b, c) {
        return b.src(a.src), this;
    }, a;
}(), Tech.withSourceHandlers(Soundcloud), Soundcloud.registerSourceHandler(SoundcloudSourceHandler), 
Tech.registerTech("Soundcloud", Soundcloud);