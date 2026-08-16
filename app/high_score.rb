# Persists the high score to the sandboxed game-data directory so it
# survives between runs of the game.
module HighScore
  FILE = 'data/highscore.txt'

  def self.load(_args)
    raw = DR.read_file(FILE)
    raw ? raw.strip.to_i : 0
  rescue StandardError
    0
  end

  def self.save(args)
    DR.write_file(FILE, args.state.score.to_s)
  rescue StandardError
    nil
  end
end
