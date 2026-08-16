# Tunable numbers for the whole game live here so balancing is a
# one-stop-shop instead of a scavenger hunt through every file.
module C
  SCREEN_W = 1280
  SCREEN_H = 720

  # --- Formation grid -------------------------------------------------
  COLS = 8
  ROWS = 5
  COL_SPACING = 100
  ROW_SPACING = 58
  FORMATION_TOP_Y = 612
  FORMATION_LEFT_X = 640 - (COLS - 1) * COL_SPACING / 2.0

  # --- Player -----------------------------------------------------------
  # Sized to roughly match the generated player sprite's 11x14 pixel
  # grid aspect ratio (see sprite_gen.rb).
  PLAYER_W = 34
  PLAYER_H = 44
  PLAYER_Y = 56
  PLAYER_SPEED = 8
  PLAYER_FIRE_COOLDOWN = 16
  PLAYER_BULLET_SPEED = 13
  PLAYER_BULLET_W = 5
  PLAYER_BULLET_H = 18
  PLAYER_LIVES_START = 3
  PLAYER_RESPAWN_DELAY = 90
  PLAYER_INVULN_TICKS = 150

  # --- Enemies ------------------------------------------------------------
  ENEMY_BULLET_SPEED = 6.5
  ENEMY_BULLET_W = 6
  ENEMY_BULLET_H = 14

  # --- Explosion spritesheet (explosion-sheet.png is 224x32 == 7 frames) --
  EXPLOSION_FRAME_COUNT = 7
  EXPLOSION_FRAME_W = 32
  EXPLOSION_FRAME_H = 32
  EXPLOSION_DURATION = 35

  STAR_COUNT = 90
end
