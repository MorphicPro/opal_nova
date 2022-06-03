// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

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
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Working MINIO
let Uploaders = {}

Uploaders.S3 = function(entries, onViewError){
  entries.forEach(entry => {
    let {full_string, medium_string, small_string} = entry.meta

    // console.debug(entry.file)
    var blob = new Blob([entry.file], {type: entry.file.type});
    let xhr = new XMLHttpRequest()
    onViewError(() => xhr.abort())
    xhr.onload = () => {
      if(xhr.status === 200){
        console.debug(entry.file)
        const imageUrl = `https://morphic-pro.imgix.net/opalnova/${entry.file.name}`;

        fetch(imageUrl + "?w=600")
        .then(response => response.blob())
        .then(imageBlob => {
            let md_xhr = new XMLHttpRequest()

            md_xhr.open("PUT", medium_string, true)
            md_xhr.send(imageBlob)
        });

        fetch(imageUrl + "?w=300&h=200&fit=crop")
          .then(response => response.blob())
          .then(imageBlob => {
              let sm_xhr = new XMLHttpRequest()
              sm_xhr.open("PUT", small_string, true)
              sm_xhr.send(imageBlob)
          });
        setTimeout(() => {entry.progress(100)}, 1000)
        
      }else{
        entry.error()
      }
    }
    xhr.onerror = () => entry.error()
    xhr.upload.addEventListener("progress", (event) => {
      // console.debug(event)
      if(event.lengthComputable){
        let percent = Math.round((event.loaded / event.total) * 100)
        if(percent < 100){ entry.progress(percent) }
      }
    }) 

    xhr.open("PUT", full_string, true)
    xhr.send(blob)
  })
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {uploaders: Uploaders, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", (info) => {
  //hides loading bar
  topbar.hide();

  console.debug(info);
  // liveredirects/livepatches tracked as a page view
  if (["redirect", "patch"].includes(info.detail.kind)) {
    // window.analytics.page();
  }
});

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug()
// liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// liveSocket.disableLatencySim()

window.liveSocket = liveSocket

