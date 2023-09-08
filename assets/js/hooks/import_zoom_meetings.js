import { v5 as uuidv5 } from 'uuid';

var FILES = []

ImportZoomMeetings = {
  mounted() {

    this.handleEvent("meeting-created", incoming => {
      this.pushEvent("meeting-uploading", { id: incoming.id })
      incoming.files.map(async incomingFile => {
        const file = FILES[incomingFile.key]
        const fileData = await file.handle.getFile();
        await fetch(incomingFile.url, {
          method: "PUT",
          body: fileData,
          headers: {
            "Content-type": "application/json; charset=UTF-8",
          },
        });
        this.pushEvent("meeting-uploaded", { id: incoming.id })
      })

    })

    this.el.addEventListener("click", async e => {
      const directoryHandle = await window.showDirectoryPicker();
      const directories = await getDirectories(directoryHandle)
      directories.map(async directory => {
        const meetingAttrs = await getMeetingAttrs(directory)
        this.pushEvent("create-meeting", meetingAttrs)
      })
    })
  }
}

async function getDirectories(handle) {
  var directories = []
  for await (const [name, innerHandle] of handle) {
    if (innerHandle.kind == 'directory') directories.push([name, innerHandle])
  }
  return directories
}

async function getMeetingAttrs([name, directoryHandle]) {
  var files = []
  const result = await getFiles(directoryHandle, files)
  files = result.files
  external_id = result.externalId
  const attrs = { name, files, external_id, source: "zoom", upload_status: "created" }
  return attrs
}

async function getFiles(directoryHandle, files) {
  var externalId
  for await (const [fileName, fileHandle] of directoryHandle) {
    if (fileHandle.name.includes(".m4a") || fileHandle.name.includes(".txt")) {
      const key = uuidv5(fileName, uuidv5.URL)
      const { lastModified } = await fileHandle.getFile()
      const attrs = { name: fileName, handle: fileHandle, lastModified }
      FILES[key] = attrs
      files.push({ key, ...attrs })
    }
    if (fileHandle.name === "recording.conf") {
      const file = await fileHandle.getFile()
      const text = await file.text()
      const result = JSON.parse(text)
      externalId = result.magic_number
    }
  }
  return { files, externalId }
}

export default ImportZoomMeetings