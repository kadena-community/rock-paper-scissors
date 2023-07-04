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

  (defun commit(
    id           : string
    player1      : string
    player2      : string
    player1-move : string
    player2-move : string)
    0)

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
    "Draw")

  )
