import { v5 as uuidv5 } from 'uuid';

var FILES = []
var DIRECTORIES = []

ImportZoomMeetings = {
  mounted() {

    this.handleEvent("meeting-exists", e => {
      createMeeting(this)
    })

    this.handleEvent("meeting-created", async incoming => {
      this.pushEvent("meeting-uploading", { id: incoming.id })
      await uploadMeeting(incoming)
      this.pushEvent("meeting-uploaded", { id: incoming.id })
      await createMeeting(this)
    })

    this.el.addEventListener("click", async e => {
      const directoryHandle = await window.showDirectoryPicker();
      DIRECTORIES = await getDirectories(directoryHandle)
      this.pushEvent("upload-started", { directories: DIRECTORIES.length })
      createMeeting(this)
    })
  }
}

async function createMeeting(hook) {
  const directory = DIRECTORIES.pop()
  if (directory) hook.pushEvent("create-meeting", await getMeetingAttrs(directory))
}

async function uploadMeeting(incoming) {
  for await (const incomingFile of incoming.files) {
    const file = FILES[incomingFile.key]
    const fileData = await file.handle.getFile();
    return await fetch(incomingFile.url, {
      method: "PUT",
      body: fileData,
      headers: {
        "Content-type": "application/json; charset=UTF-8",
      },
    });
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
      FILES[`/meetings/${key}`] = attrs
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