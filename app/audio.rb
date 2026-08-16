# Thin wrapper around one-shot sound effects so the rest of the
# codebase doesn't need to know the outputs API for it.
module Audio
  def self.play(args, path)
    args.outputs.sounds << path
  end
end
