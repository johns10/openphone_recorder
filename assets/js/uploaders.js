
import * as UpChunk from "@mux/upchunk"

function S3(entries, onViewError) {
  entries.forEach(async (entry) => {
    const { file, meta: { url } } = entry
    let xhr = new XMLHttpRequest()
    onViewError(() => xhr.abort())
    xhr.onload = () => xhr.status === 200 ? entry.progress(100) : entry.error()
    xhr.onerror = () => entry.error()

    xhr.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable) {
        let percent = Math.round((event.loaded / event.total) * 100)
        if (percent < 100) { entry.progress(percent) }
      }
    })

    xhr.open("PUT", url, true)
    xhr.send(entry.file)
  })
}

export default { S3 }
