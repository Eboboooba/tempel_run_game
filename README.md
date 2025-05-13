# tempel_run_game
a temepl run like game where your catecter avoids enemyes to achive the highest score


This project is a 2D endless runner game created with the Ruby2D framework. Inspired by games like Temple Run and Subway Surfers, the player controls a constantly moving character who must avoid falling enemies. The goal is to survive as long as possible while the score increases over time. As the game progresses, it becomes more challenging by speeding up enemy movement and increasing their spawn rate.

The main logic of the game revolves around a few core concepts: game state management, sprite animation, collision detection, input handling, and level progression. The game uses a boolean flag $game_running to determine whether the player is actively playing or if the game is in a game-over state. The score is continuously incremented during gameplay, and a difficulty level counter increases every 30 seconds, modifying how quickly enemies appear and how fast they fall.

The character is represented by multiple sprite sheets, which enable different animations depending on the action being performed. When the player is idle or jumping, a static or jumping sprite is shown. When moving left or right, the sprite changes to show the corresponding running animation. Gravity is simulated with a vertical velocity variable ($velocity_y) and a flag ($on_ground) to determine if the player can jump. Jumping resets the vertical velocity and triggers a jump animation along with a sound effect.

Enemy behavior is relatively simple: enemies fall vertically from random positions at the top of the screen. Each enemy is assigned a speed that increases as the difficulty level rises. If an enemy collides with the player, the game ends and a game-over screen is displayed with the final score and level. Collision detection is handled through a basic bounding-box algorithm that checks whether the rectangles representing the player and an enemy overlap.

A level-up system is implemented to gradually increase the difficulty. Every 30 seconds, the level increases, which triggers a visual flash on the screen and causes more enemies to be spawned faster. A message is also displayed to notify the player of the new level.

Game audio includes a looping background soundtrack and a jump sound effect. These audio elements enhance the immersive experience. Input is handled through the keyboard: the left and right arrow keys move the player horizontally, the up arrow key initiates a jump, and the "R" key allows the player to restart the game after a game over.

When the game is restarted, a function called initialize_game resets all variables, clears enemies, resets the score and difficulty, and restores the player to the starting position. It also removes any visual game-over elements to prepare the game for a fresh start.

Overall, this Ruby2D project demonstrates how to combine animation, physics simulation, audio feedback, and increasing difficulty to create a dynamic and engaging endless runner game. The code is organized with modular functions for creating enemies, handling collisions, updating score, and managing the game state, which makes it easy to understand and extend.

