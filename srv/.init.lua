local fm = require "fullmoon"
local os = require "os"

-- Set the maximum payload size to 500MB
ProgramMaxPayloadSize(1024 * 1024 * 500)
--LaunchBrowser()

fm.setRoute("/", "/index.html")
fm.setRoute({"/api/upload", method = "POST"}, function(r)
  if r.params.multipart.file then
    Barf("input", r.params.multipart.file.data)
    os.remove("output.wav")
    os.execute("ffmpeg -i input -ar 16000 -ac 1 -c:a pcm_s16le srv/output.wav")
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

