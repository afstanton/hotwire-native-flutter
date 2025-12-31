const String turboJs = r'''
(() => {
  const TURBO_LOAD_TIMEOUT = 30000

  class TurboNative {
    constructor() {
      this.messageHandler = window.TurboNative
    }

    registerAdapter() {
      if (window.Turbo) {
        Turbo.registerAdapter(this)
      } else if (window.Turbolinks) {
        Turbolinks.controller.adapter = this
      } else {
        throw new Error("Failed to register the TurboNative adapter")
      }
    }

    pageLoaded() {
      let restorationIdentifier = ""

      if (window.Turbo) {
        restorationIdentifier = Turbo.navigator.restorationIdentifier
      } else if (window.Turbolinks) {
        restorationIdentifier = Turbolinks.controller.restorationIdentifier
      }

      this.postMessageAfterNextRepaint("pageLoaded", { restorationIdentifier })
    }

    pageLoadFailed() {
      this.postMessage("pageLoadFailed")
    }

    errorRaised(error) {
      this.postMessage("errorRaised", { error: error })
    }

    visitLocationWithOptionsAndRestorationIdentifier(location, options, restorationIdentifier) {
      if (window.Turbo) {
        if (Turbo.navigator.locationWithActionIsSamePage(new URL(location), options.action)) {
          Turbo.navigator.startVisit(location, restorationIdentifier, { "action": "replace" })
        } else {
          Turbo.navigator.startVisit(location, restorationIdentifier, options)
        }
      } else if (window.Turbolinks) {
        if (Turbolinks.controller.startVisitToLocationWithAction) {
          Turbolinks.controller.startVisitToLocationWithAction(location, options.action, restorationIdentifier)
        } else {
          Turbolinks.controller.startVisitToLocation(location, restorationIdentifier, options)
        }
      }
    }

    clearSnapshotCache() {
      if (window.Turbo) {
        Turbo.session.clearCache()
      }
    }

    cacheSnapshot() {
      if (window.Turbo) {
        Turbo.session.view.cacheSnapshot()
      }
    }

    issueRequestForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.issueRequest()
      }
    }

    changeHistoryForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.changeHistory()
      }
    }

    loadCachedSnapshotForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.loadCachedSnapshot()
      }
    }

    loadResponseForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.loadResponse()
      }
    }

    cancelVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.cancel()
      }
    }

    visitProposedToLocation(location, options) {
      if (window.Turbo && Turbo.navigator.locationWithActionIsSamePage(location, options.action)) {
        this.postMessage("visitProposalScrollingToAnchor", { location: location.toString(), options: options })
        Turbo.navigator.view.scrollToAnchorFromLocation(location)
      } else if (window.Turbo && Turbo.navigator.location?.href === location.href) {
        this.postMessage("visitProposalRefreshingPage", { location: location.toString(), options: options })
        this.visitLocationWithOptionsAndRestorationIdentifier(location, options, Turbo.navigator.restorationIdentifier)
      } else {
        this.postMessage("visitProposed", { location: location.toString(), options: options })
      }
    }

    visitProposedToLocationWithAction(location, action) {
      this.visitProposedToLocation(location, { action })
    }

    visitStarted(visit) {
      this.currentVisit = visit
      this.postMessage("visitStarted", { identifier: visit.identifier, hasCachedSnapshot: visit.hasCachedSnapshot(), isPageRefresh: visit.isPageRefresh || false })
      this.issueRequestForVisitWithIdentifier(visit.identifier)
      this.changeHistoryForVisitWithIdentifier(visit.identifier)
      this.loadCachedSnapshotForVisitWithIdentifier(visit.identifier)
    }

    visitRequestStarted(visit) {
      this.postMessage("visitRequestStarted", { identifier: visit.identifier })
    }

    visitRequestCompleted(visit) {
      this.postMessage("visitRequestCompleted", { identifier: visit.identifier })
      this.loadResponseForVisitWithIdentifier(visit.identifier)
    }

    visitRequestFailedWithStatusCode(visit, statusCode) {
      const location = visit.location.toString()

      if (statusCode <= 0) {
        this.postMessage("visitRequestFailedWithNonHttpStatusCode", { location: location, identifier: visit.identifier })
      } else {
        this.postMessage("visitRequestFailed", { location: location, identifier: visit.identifier, statusCode: statusCode })
      }
    }

    visitRequestFinished(visit) {
      this.postMessage("visitRequestFinished", { identifier: visit.identifier })
    }

    visitRendered(visit) {
      this.postMessageAfterNextRepaint("visitRendered", { identifier: visit.identifier })
    }

    visitCompleted(visit) {
      this.postMessage("visitCompleted", { identifier: visit.identifier, restorationIdentifier: visit.restorationIdentifier })
    }

    formSubmissionStarted(formSubmission) {
      this.postMessage("formSubmissionStarted", { location: formSubmission.location.toString() })
    }

    formSubmissionFinished(formSubmission) {
      this.postMessage("formSubmissionFinished", { location: formSubmission.location.toString() })
    }

    pageInvalidated() {
      this.postMessage("pageInvalidated")
    }

    linkPrefetchingIsEnabledForLocation(location) {
      return false
    }

    log(message) {
      this.postMessage("log", { message: message })
    }

    postMessage(name, data = {}) {
      data["timestamp"] = Date.now()
      if (this.messageHandler && this.messageHandler.postMessage) {
        this.messageHandler.postMessage(JSON.stringify({ name: name, data: data }))
      }
    }

    postMessageAfterNextRepaint(name, data) {
      if (document.hidden) {
        this.postMessage(name, data);
      } else {
        var postMessage = this.postMessage.bind(this, name, data)
        requestAnimationFrame(() => {
          requestAnimationFrame(postMessage)
        })
      }
    }
  }

  addEventListener("error", event => {
    const error = event.message + " (" + event.filename + ":" + event.lineno + ":" + event.colno + ")"
    window.turboNative.errorRaised(error)
  }, false)

  window.turboNative = new TurboNative()

  const setup = function() {
    window.turboNative.registerAdapter()
    window.turboNative.pageLoaded()

    document.removeEventListener("turbo:load", setup)
    document.removeEventListener("turbolinks:load", setup)
  }

  const setupOnLoad = () => {
    document.addEventListener("turbo:load", setup)
    document.addEventListener("turbolinks:load", setup)

    setTimeout(() => {
      if (!window.Turbo && !window.Turbolinks) {
        window.turboNative.pageLoadFailed()
      }
    }, TURBO_LOAD_TIMEOUT)
  }

  if (window.Turbo || window.Turbolinks) {
    setup()
  } else {
    setupOnLoad()
  }
})()
''';
