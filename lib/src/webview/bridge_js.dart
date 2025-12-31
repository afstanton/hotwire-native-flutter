const String bridgeJs = r'''
(() => {
  class NativeBridge {
    constructor() {
      this.supportedComponents = []
      this.registerCalled = new Promise(resolve => this.registerResolver = resolve)
      document.addEventListener("web-bridge:ready", async () => {
        await this.setAdapter()
      })
    }

    async setAdapter() {
      await this.registerCalled
      this.webBridge.setAdapter(this)
    }

    register(component) {
      if (Array.isArray(component)) {
        this.supportedComponents = this.supportedComponents.concat(component)
      } else {
        this.supportedComponents.push(component)
      }

      this.registerResolver()
      this.notifyBridgeOfSupportedComponentsUpdate()
    }

    unregister(component) {
      const index = this.supportedComponents.indexOf(component)
      if (index != -1) {
        this.supportedComponents.splice(index, 1)
        this.notifyBridgeOfSupportedComponentsUpdate()
      }
    }

    notifyBridgeOfSupportedComponentsUpdate() {
      if (this.isWebBridgeAvailable) {
        this.webBridge.adapterDidUpdateSupportedComponents()
      }
    }

    supportsComponent(component) {
      return this.supportedComponents.includes(component)
    }

    replyWith(message) {
      if (this.isWebBridgeAvailable) {
        this.webBridge.receive(message)
      }
    }

    receive(message) {
      this.postMessage(message)
    }

    get platform() {
      return "flutter"
    }

    postMessage(message) {
      if (window.HotwireNative && window.HotwireNative.postMessage) {
        window.HotwireNative.postMessage(JSON.stringify(message))
      }
    }

    get isWebBridgeAvailable() {
      return this.webBridge != null
    }

    get webBridge() {
      if (window.HotwireNative && window.HotwireNative.web) {
        return window.HotwireNative.web
      }
      if (window.Strada && window.Strada.web) {
        return window.Strada.web
      }
      return null
    }
  }

  window.nativeBridge = new NativeBridge()
  window.nativeBridge.postMessage("ready")
})()
''';
