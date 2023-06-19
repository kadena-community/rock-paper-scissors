(module rock-paper-scissors GOVERNANCE
  @model [
    (defproperty game-result(move1:string move2:string expected:string)
      (when 
        (and (= player1-move move1) (= player2-move move2))
        (= result expected)))
  ]
  (defcap GOVERNANCE() false)

  (defschema GAME
    player1      : string
    player2      : string
    player1-move : string
    player2-move : string)
  (deftable games:{GAME})

  (defun draw(
    id           : string
    player1      : string
    player2      : string
    player1-move : string
    player2-move : string)
    (insert games id 
      { 'player1      : player1
      , 'player2      : player2
      , 'player1-move : player1-move
      , 'player2-move : player2-move }))

  (defun reveal(
    id           : string
    player1-move : string
    player1-salt : string
    player2-move : string
    player2-salt : string)
    @model [
      (property (game-result "rock" "scissors" "Player 1 wins"))
      (property (game-result "rock" "rock" "Draw"))
      (property (game-result "rock" "paper" "Player 2 wins"))
      (property (game-result "paper" "scissors" "Player 2 wins"))
      (property (game-result "paper" "rock" "Player 1 wins"))
      (property (game-result "paper" "paper" "Draw"))
      (property (game-result "scissors" "scissors" "Draw"))
      (property (game-result "scissors" "rock" "Player 2 wins"))
      (property (game-result "scissors" "paper" "Player 1 wins"))
    ]
    (with-read games id
      { 'player1      := player1
      , 'player2      := player2
      , 'player1-move := saved-player1-move
      , 'player2-move := saved-player2-move }
      (enforce 
        (= saved-player1-move (hash (format "{}-{}" [player1-move player1-salt])))
        "Player 1 revealed move does not match saved move")
      (enforce 
        (= saved-player2-move (hash (format "{}-{}" [player2-move player2-salt])))
        "Player 2 revealed move does not match saved move")
        (cond ((= player1-move player2-move) "Draw")
              ((and (= player1-move "rock") (= player2-move "scissors")) "Player 1 wins")
              ((and (= player1-move "scissors") (= player2-move "paper")) "Player 1 wins")
              ((and (= player1-move "paper") (= player2-move "rock")) "Player 1 wins")
              "Player 2 wins")))
  )

(create-table games)
