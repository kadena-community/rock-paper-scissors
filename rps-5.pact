(module rock-paper-scissors GOVERNANCE
  @model [
    (defproperty is-valid-move(move:string)
      (or (= move "rock") 
          (or (= move "paper") (= move "scissors"))))
    (defproperty allow-draw(move1:string move2:string)
      (when (= move1 move2) (= result "Draw")))
    (defproperty allow-win(move1:string move2:string)
      (when (or (and (= move1 "rock") (= move2 "scissors"))
                (or (and (= move1 "paper") (= move2 "rock"))
                    (and (= move1 "scissors") (= move2 "paper"))))
        (= result "Player 1 wins")))
    (defproperty allow-lose(move1:string move2:string)
      (when (or (and (= move1 "scissors") (= move2 "rock"))
                (or (and (= move1 "rock") (= move2 "paper"))
                    (and (= move1 "paper") (= move2 "scissors"))))
        (= result "Player 2 wins")))
  ]
  (defcap GOVERNANCE() false)

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
      (or (= move "rock") 
      (or (= move "paper") (= move "scissors")))
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
      (cond ((= player1-move player2-move) "Draw")
            ((and (= player1-move "rock") (= player2-move "scissors")) "Player 1 wins")
            ((and (= player1-move "scissors") (= player2-move "paper")) "Player 1 wins")
            ((and (= player1-move "paper") (= player2-move "rock")) "Player 1 wins")
            "Player 2 wins")))

  )

(create-table games)
