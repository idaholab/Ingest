// Bring in Phoenix channels client library:
import { Socket } from "phoenix"

// And connect to the path in "lib/ingest_web/endpoint.ex". We pass the
// token for authentication. Read below how it should be used.

export var Notifications = {
  mounted() {
    let socket = new Socket("/socket", { params: { token: window.userToken } })

    socket.connect()

    let channel = socket.channel(`notifications:${window.userId}`, {})
    channel.join()
      .receive("error", resp => { console.log("Unable to join", resp) })

    channel.on("new_notification", payload => {
      this.pushEventTo(this.el, "new_notification", payload)
    })
  }
}
