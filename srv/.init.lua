local fm = require "fullmoon"
local os = require "os"

-- Set the maximum payload size to 500MB
ProgramMaxPayloadSize(1024 * 1024 * 500)
--LaunchBrowser()

fm.setRoute("/", "/index.html")
fm.setRoute({"/api/upload", method = "POST"}, function(r)
  -- TODO: Install ffmpeg and whisper-cpp
  -- TODO: Download ggm-small.en.bin if it doesn't exist
  -- TODO: Make it cross-platform
  -- TODO: Don't save output to srv/ folder, refactor `make dev` to compress in the latest files
  -- TODO: Add an audio speed option
  if r.params.multipart.file then
    Barf("input", r.params.multipart.file.data)
    os.remove("output.wav")
    os.execute("ffmpeg -i input -ar 16000 -ac 1 -y -c:a pcm_s16le srv/output.wav")
    local handle = io.popen("brew --prefix whisper-cpp")
    local whisper_path = handle:read("*a")
    handle:close()
    whisper_path = whisper_path:gsub("\n", "")
    os.execute("GGML_METAL_PATH_RESOURCES=\"%s/share/whisper-cpp\" whisper-cpp srv/output.wav -m ggml-small.en.bin > srv/output.txt" % {whisper_path})
  end
  return "File uploaded"
end)

fm.setRoute({"/output.txt", method = "GET"}, fm.serveAsset)
fm.setRoute({"/output.wav", method = "GET"}, fm.serveAsset)

fm.run()

