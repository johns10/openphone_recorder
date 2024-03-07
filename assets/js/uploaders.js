
import * as UpChunk from "@mux/upchunk"

function S3(entries, onViewError) {
  entries.forEach(async (entry) => {
    const { file, meta: { endpoint } } = entry
    const upload = UpChunk.createUpload({ endpoint, file })
    onViewError(() => upload.pause())
    upload.on("error", (e) => entry.error(e.detail.message))
    upload.on("progress", (e) => entry.progress(e.detail))
  })
}

export default { S3 }
