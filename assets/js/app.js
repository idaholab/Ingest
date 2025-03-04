// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Sortable from "../vendor/Sortable.js";
import { Notifications } from "./user_socket.js";
import Alpine from "alpinejs";

window.Alpine = Alpine;
Alpine.start();

// Custom Hooks - Primarily used for custom Javascript such as the Sortable.js library on the form builder
let Hooks = {};

Hooks.FormBuilderFields = {
  mounted() {
    var sortable = Sortable.create(this.el, {
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      onEnd: (e) => {
        let params = { old: e.oldIndex, new: e.newIndex, ...e.item.dataset };
        this.pushEventTo(this.el, "reposition", params);
      },
    });
  },
};

Hooks.Sortable = {
  mounted() {
    let el = this.el;
    let sortable = Sortable.create(el, {
      animation: 150,
      onEnd: (evt) => {
        let ids = Array.from(el.children).map(row => row.dataset.id);
        this.pushEvent("reorder_fields", { order: ids });
      }
    });
  }
};

Hooks.UploadBox = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      let file_input = document.getElementById(this.el.dataset.fileId);
      file_input.click();
    });
  },
};

Hooks.ClipboardCopy = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      let input = this.el.dataset.body;

      const storage = document.createElement("textarea");
      storage.value = input;
      this.el.appendChild(storage);

      // Copy the text in the fake `textarea` and remove the `textarea`
      storage.select();
      storage.setSelectionRange(0, 99999);
      document.execCommand("copy");
      this.el.removeChild(storage);
    });
  },
};

Hooks.Notifications = Notifications;

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
