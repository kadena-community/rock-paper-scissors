(module rock-paper-scissors GOVERNANCE
  @model [
    (defproperty is-valid-move(move:string)
      (or (= move ROCK) 
          (or (= move PAPER) (= move SCISSORS))))
    (defproperty allow-draw(move1:string move2:string)
      (when (= move1 move2) (= result DRAW)))
    (defproperty allow-win(move1:string move2:string)
      (when (or (and (= move1 ROCK) (= move2 SCISSORS))
                (or (and (= move1 PAPER) (= move2 ROCK))
                    (and (= move1 SCISSORS) (= move2 PAPER))))
        (= result PLAYER1-WINS)))
    (defproperty allow-lose(move1:string move2:string)
      (when (or (and (= move1 SCISSORS) (= move2 ROCK))
                (or (and (= move1 ROCK) (= move2 PAPER))
                    (and (= move1 PAPER) (= move2 SCISSORS))))
        (= result PLAYER2-WINS)))
  ]
  (defcap GOVERNANCE() false)
  (defconst ROCK 'rock)
  (defconst PAPER 'paper)
  (defconst SCISSORS 'scissors)

  (defconst DRAW 'Draw)
  (defconst PLAYER1-WINS "Player 1 wins")
  (defconst PLAYER2-WINS "Player 2 wins")

  (defschema game
    player1      : string
    player2      : string
    player1-move : string
    player2-move : string)
  (deftable games:{game})

  (defun commit(
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

  (defun enforce-valid-move(move:string)
    (enforce 
      (or (= move ROCK) 
      (or (= move PAPER) (= move SCISSORS)))
      "Invalid move"))

  (defun reveal(
    id           : string
    player1-move : string
    player1-salt : string
    player2-move : string
    player2-salt : string)
    @model [
      (property (is-valid-move player1-move))
      (property (is-valid-move player2-move))
      (property (allow-draw player1-move player2-move))
      (property (allow-win player1-move player2-move))
      (property (allow-lose player1-move player2-move))
    ]
    (with-read games id
      { 'player1-move := commited-player1-move
      , 'player2-move := commited-player2-move }
      (enforce 
        (= (hash (format "{}-{}" [player1-move player1-salt])) commited-player1-move)
        "Player 1 revealed move does not match saved move")
      (enforce 
        (= (hash (format "{}-{}" [player2-move player2-salt])) commited-player2-move)
        "Player 2 revealed move does not match saved move")
      (enforce-valid-move player1-move)
      (enforce-valid-move player2-move)
      (cond ((= player1-move player2-move) DRAW)
            ((and (= player1-move ROCK) (= player2-move SCISSORS)) PLAYER1-WINS)
            ((and (= player1-move SCISSORS) (= player2-move PAPER)) PLAYER1-WINS)
            ((and (= player1-move PAPER) (= player2-move ROCK)) PLAYER1-WINS)
            PLAYER2-WINS)))

  )

(create-table games)
