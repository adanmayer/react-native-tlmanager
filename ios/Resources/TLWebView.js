 (function() {
    function MobileClient(messageHandler) {
      this.messageHandler = messageHandler
    }
  
    MobileClient.prototype = {
      clientInitialized: function() {
        this.postMessageAfterNextRepaint("clientInitialized", { })
      },
  
      errorRaised: function(error) {
        this.postMessage("errorRaised", { error: error })
      },
  
      postMessage: function(name, data) {
        this.messageHandler.postMessage({ name: name, data: data || {} })
      },
  
      postMessageAfterNextRepaint: function(name, data) {
        // Post immediately if document is hidden or message may be queued by call to rAF
        if (document.hidden) {
          this.postMessage(name, data);
        } else {
          var postMessage = this.postMessage.bind(this, name, data)
          requestAnimationFrame(function() {
                                requestAnimationFrame(postMessage)
                              })
        }
      }
    }
  
    this.mobileClient = new WebView(webkit.messageHandlers.MsgBridge)
  
    addEventListener("error", function(event) {
                     var error = event.message + " (" + event.filename + ":" + event.lineno + ":" + event.colno + ")"
                     mobileClient.errorRaised(error)
                     }, false)
  
    mobileClient.clientInitialized()
})()
