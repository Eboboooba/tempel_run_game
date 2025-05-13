require 'ruby2d'

set width: 612
set height: 408
set title: "Subway Surfers"
set fps_cap: 60

# Game state variables
$game_running = true
$score = 0
$game_over_elements = []
$needs_restart = false
$level_up_flash = nil
$level_up_timer = 0
$level_up_duration = 0.5

# Game objects
$enemies = []
$spawn_timer = 0
$spawn_interval = 5

# Difficulty settings
$difficulty_level = 1
$difficulty_timer = 0
$difficulty_increase_interval = 30
$enemies_per_spawn = 1
$max_enemies = 10

 # Creates a visual flash effect when the player reaches a new difficulty level
  # Shows a semi-transparent yellow overlay across the screen
  # Sets a timer to remove the effect after a short duration
def create_level_up_effect
  if $level_up_flash
    $level_up_flash.remove
  end
  
  $level_up_flash = Rectangle.new(
    x: 0,
    y: 0,
    width: Window.width,
    height: Window.height,
    color: 'yellow',
    opacity: 0.3
  )
  
  $level_up_timer = 0
end

  # This function resets all game variables and objects to their starting values
  # It's called at the beginning and when restarting the game
  # Handles:
  # - Resetting score, game state, and difficulty level
  # - Removing all enemies and effects
  # - Resetting player position
  # - Setting up text displays for score and level
def initialize_game
  $game_running = true
  $score = 0
  $spawn_timer = 0
  
  # Reset difficulty
  $difficulty_level = 1
  $difficulty_timer = 0
  $enemies_per_spawn = 1
  $spawn_interval = 5
  
  # Remove any level up effect
  if $level_up_flash
    $level_up_flash.remove
    $level_up_flash = nil
    $level_up_timer = 0
  end
  
  # Remove any existing game over elements
  $game_over_elements.each do |element|
    element.remove if element
  end
  $game_over_elements = []
  
  # Remove level up message if it exists
  if $level_up_message
    $level_up_message.remove
    $level_up_message = nil
  end
  
  # Remove any existing enemies
  $enemies.each do |enemy|
    enemy.remove if enemy && enemy.data[:active]
  end
  $enemies = []
  
  # Reset score display
  if defined?($score_text) && $score_text
    $score_text.text = "Score: 0"
  else
    $score_text = Text.new(
      "Score: 0",
      x: 10,
      y: 10,
      size: 20,
      color: 'white'
    )
  end
  
  # Reset difficulty display
  if defined?($difficulty_text) && $difficulty_text
    $difficulty_text.text = "Level: 1"
  else
    $difficulty_text = Text.new(
      "Level: 1",
      x: 10,
      y: 40,
      size: 20,
      color: 'white'
    )
  end
  
  # Reset player position
  if defined?($current_sprite) && $current_sprite
    $current_sprite.x = 100
    $current_sprite.y = 300
  end
end

# Background image
background = Image.new('backround1.png')


# Initialize player sprites
begin
  # Main sprite for jump/fly
  $sprite = Sprite.new(
    'catecter.png',
    x: 100,
    y: 300,
    clip_width: 60,
    width: 60,
    height: 60,
    animations: {
      fly: 1..5
    },
    time: 100
  )

  # Running sprite (right-facing)
  $run_sprite_right = Sprite.new(
    'catecter_run.png',   
    x: 100,
    y: 300,
    clip_width: 60,
    width: 60,
    height: 60,
    animations: {
      run: 1..4
    },
    time: 100
  )

  # Running sprite (left-facing)
  $run_sprite_left = Sprite.new(
    'catecter_run_left.png',   
    x: 100,
    y: 300,
    clip_width: 60,
    width: 60,
    height: 60,
    animations: {
      run: 1..5
    },
    time: 100
  )
  
  $current_sprite = $sprite
  
  # Initially, hide the running sprites
  $run_sprite_right.remove
  $run_sprite_left.remove

end

# Enemy creation function
def create_enemy(x_position)
  begin
    enemy = Image.new(
      'enemy.png',
      x: x_position,
      y: -60,
      width: 70,
      height: 70
    )
  end
  
  # Set enemy speed based on difficulty level
  base_velocity = 3
  velocity_increase = $difficulty_level * 0.5
  max_velocity = 10
  
  enemy_velocity = [base_velocity + velocity_increase, max_velocity].min
  enemy_velocity += rand(0..2)  # Add a small random factor
  
  enemy.data = {
    velocity: enemy_velocity,
    active: true
  }
  
  return enemy
end

# Score display
$score_text = Text.new(
  "Score: 0",
  x: 10,
  y: 10,
  size: 20,
  color: 'white'
)

# Difficulty level display
$difficulty_text = Text.new(
  "Level: 1",
  x: 10,
  y: 40,
  size: 20,
  color: 'white'
)

# Sounds
begin
  $jump_sound = Sound.new('jump.wav')
  $music = Music.new('backround_sound.wav')
  $music.loop = true
  $music.play
end

# Physics variables
$gravity = 0.8
$jump_force = -12
$velocity_y = 0
$on_ground = true
$move_speed = 5

# Movement state
$moving_left = false
$moving_right = false

  # Determines if the player character overlaps with an enemy
  # Uses axis-aligned bounding box (AABB) collision detection
  # Returns true if there's a collision, false otherwise
def check_collision(player, enemy)
  player_x = player.x
  player_y = player.y
  player_width = 60
  player_height = 60
  
  enemy_x = enemy.x
  enemy_y = enemy.y
  enemy_width = 70
  enemy_height = 70
  
  return (
    player_x < enemy_x + enemy_width &&
    player_x + player_width > enemy_x &&
    player_y < enemy_y + enemy_height &&
    player_y + player_height > enemy_y
  )
end

 # Creates and displays the game over screen
  # Shows final score and level reached
  # Provides restart instructions
  # Returns an array of the created UI elements for later cleanup
def show_game_over(final_score)
  # Background overlay
  overlay = Rectangle.new(
    x: 0,
    y: 0,
    width: Window.width,
    height: Window.height,
    color: 'black',
    opacity: 0.7
  )
  
  # Game over text
  game_over_text = Text.new(
    "GAME OVER",
    x: Window.width/2 - 100,
    y: Window.height/2 - 50,
    size: 40,
    color: 'red'
  )
  
  # Score text
  final_score_text = Text.new(
    "Final Score: #{final_score}",
    x: Window.width/2 - 80,
    y: Window.height/2 + 10,
    size: 25,
    color: 'white'
  )
  
  # Difficulty level reached
  level_text = Text.new(
    "Level Reached: #{$difficulty_level}",
    x: Window.width/2 - 90,
    y: Window.height/2 + 40,
    size: 25,
    color: 'white'
  )
  
  # Restart instructions
  restart_text = Text.new(
    "Press 'R' to restart",
    x: Window.width/2 - 90,
    y: Window.height/2 + 80,
    size: 20,
    color: 'white'
  )
  
  return [overlay, game_over_text, final_score_text, level_text, restart_text]
end

  # Creates a temporary text message announcing the level increase
  # Centers the message on screen
  # Automatically removes the message after a short delay
def show_level_up_message(level)
  if $level_up_message
    $level_up_message.remove
  end
  
  $level_up_message = Text.new(
    "Level Up! #{level}",
    x: Window.width/2 - 60,
    y: Window.height/2 - 20,
    size: 25,
    color: 'yellow'
  )
  
  Window.after(2000) do
    if $level_up_message
      $level_up_message.remove
      $level_up_message = nil
    end
  end
end

# Initialize the game
initialize_game()

# Controls for player movement
on :key_down do |event|
  if $game_running
    case event.key
    when 'up'
      if $on_ground
        $velocity_y = $jump_force
        $on_ground = false
        # Switch to main sprite (jumping)
        if $current_sprite != $sprite
          $current_sprite.remove
          Window.add($sprite)
          $current_sprite = $sprite
        end
        
        if $sprite.respond_to?(:play)
          $sprite.play(animation: :fly)
        end
        
        $jump_sound.play
      end
    when 'left'
      $moving_left = true
      if $current_sprite != $run_sprite_left && $on_ground
        # Switch to left-running sprite
        $current_sprite.remove
        $run_sprite_left.x = $current_sprite.x
        $run_sprite_left.y = $current_sprite.y
        Window.add($run_sprite_left)
        
        if $run_sprite_left.respond_to?(:play)
          $run_sprite_left.play(animation: :run)
        end
        
        $current_sprite = $run_sprite_left
      end
    when 'right'
      $moving_right = true
      if $current_sprite != $run_sprite_right && $on_ground
        # Switch to right-running sprite
        $current_sprite.remove
        $run_sprite_right.x = $current_sprite.x
        $run_sprite_right.y = $current_sprite.y
        Window.add($run_sprite_right)
        
        if $run_sprite_right.respond_to?(:play)
          $run_sprite_right.play(animation: :run)
        end
        
        $current_sprite = $run_sprite_right
      end
    end
  elsif event.key == 'r'
    # Trigger game restart
    $needs_restart = true
  end
end

on :key_up do |event|
  if $game_running
    case event.key
    when 'left'
      $moving_left = false
      if $on_ground && !$moving_right
        # Switch back to main sprite when stopping
        $current_sprite.remove
        $sprite.x = $current_sprite.x
        $sprite.y = $current_sprite.y
        Window.add($sprite)
        $current_sprite = $sprite
      end
    when 'right'
      $moving_right = false
      if $on_ground && !$moving_left
        # Switch back to main sprite when stopping
        $current_sprite.remove
        $sprite.x = $current_sprite.x
        $sprite.y = $current_sprite.y
        Window.add($sprite)
        $current_sprite = $sprite
      end
    end
  end
end

  # Spawns multiple enemies based on current difficulty settings
  # Respects the maximum enemy limit to prevent overwhelming the player
  # Places enemies at random horizontal positions across the screen
def spawn_enemies
  return if $enemies.length >= $max_enemies
  
  enemies_to_spawn = [$enemies_per_spawn, $max_enemies - $enemies.length].min
  
  enemies_to_spawn.times do
    x_pos = rand(0..Window.width - 50)
    new_enemy = create_enemy(x_pos)
    $enemies << new_enemy
  end
end

  # The main game loop that runs every frame
  # Handles:
  # - Score incrementation
  # - Difficulty progression over time
  # - Player physics (gravity, jumping, movement)
  # - Enemy spawning and movement
  # - Collision detection
  # - Game over condition checking
update do
  # Check for restart request
  if $needs_restart
    initialize_game()
    $needs_restart = false
  end

  if $game_running
    # Increase score over time
    $score += 1
    $score_text.text = "Score: #{$score}"
    
    # Update difficulty level display
    $difficulty_text.text = "Level: #{$difficulty_level}"
    
    # Handle difficulty increase timer
    $difficulty_timer += (1.0/60.0)
    
    # Check if it's time to increase difficulty
    if $difficulty_timer >= $difficulty_increase_interval
      # Reset timer
      $difficulty_timer = 0
      
      # Increase difficulty
      $difficulty_level += 1
      
      # Update game parameters based on new difficulty
      $enemies_per_spawn = [$difficulty_level, $max_enemies].min
      $spawn_interval = [5.0 - ($difficulty_level * 0.3), 1.0].max
      
      # Update the difficulty text
      $difficulty_text.text = "Level: #{$difficulty_level}"
      
      # Show level up effect
      create_level_up_effect()
    end
    
    # Handle level up flash effect timing
    if $level_up_flash
      $level_up_timer += (1.0/60.0)
      
      if $level_up_timer >= $level_up_duration
        $level_up_flash.remove
        $level_up_flash = nil
      end
    end
    
    # Handle continuous movement
    if $moving_left
      $current_sprite.x -= $move_speed
    elsif $moving_right
      $current_sprite.x += $move_speed
    end
    
    # Keep character within screen bounds
    if $current_sprite.x < 0
      $current_sprite.x = 0
    elsif $current_sprite.x > Window.width - 60
      $current_sprite.x = Window.width - 60
    end
    
    # Apply gravity
    $velocity_y += $gravity
    $current_sprite.y += $velocity_y

    # Ground check
    if $current_sprite.y >= 300
      $current_sprite.y = 300
      $velocity_y = 0
      
      # Only set on_ground to true if we were falling
      if !$on_ground
        $on_ground = true
        
        # When landing, switch to the correct running sprite based on movement
        if $moving_left
          $current_sprite.remove
          $run_sprite_left.x = $current_sprite.x
          $run_sprite_left.y = $current_sprite.y
          Window.add($run_sprite_left)
          if $run_sprite_left.respond_to?(:play)
            $run_sprite_left.play(animation: :run)
          end
          $current_sprite = $run_sprite_left
        elsif $moving_right
          $current_sprite.remove
          $run_sprite_right.x = $current_sprite.x
          $run_sprite_right.y = $current_sprite.y
          Window.add($run_sprite_right)
          if $run_sprite_right.respond_to?(:play)
            $run_sprite_right.play(animation: :run)
          end
          $current_sprite = $run_sprite_right
        else
          # If not moving horizontally, switch to standing sprite
          if $current_sprite != $sprite
            $current_sprite.remove
            $sprite.x = $current_sprite.x
            $sprite.y = $current_sprite.y
            Window.add($sprite)
            $current_sprite = $sprite
          end
        end
      end
    end
    
    # Enemy spawn logic
    $spawn_timer += (1.0/60.0)
    
    if $spawn_timer >= $spawn_interval
      $spawn_timer = 0
      spawn_enemies()
    end
    
    # Update enemies
    $enemies.each do |enemy|
      if enemy.data[:active]
        # Move enemy down
        enemy.y += enemy.data[:velocity]
        
        # Check if enemy is off screen
        if enemy.y > Window.height
          enemy.remove
          enemy.data[:active] = false
        end
        
        # Check collision with player
        if check_collision($current_sprite, enemy)
          # Game over
          $game_running = false
          $game_over_elements = show_game_over($score)
        end
      end
    end
    
    # Clean up inactive enemies from array
    $enemies.reject! { |enemy| !enemy.data[:active] }
  end
end

show