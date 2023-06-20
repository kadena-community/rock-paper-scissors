(module rock-paper-scissors GOVERNANCE
  @model [
    (defproperty is-valid-move(move:string)
      (or (= move "rock") 
          (or (= move "paper") (= move "scissors"))))
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
    ]
    0)

  )
