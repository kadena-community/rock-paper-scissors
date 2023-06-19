(module rock-paper-scissors GOVERNANCE
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
              ((and (= player1-move "Rock") (= player2-move "Scissors")) "Player 1 wins")
              ((and (= player1-move "Scissors") (= player2-move "Paper")) "Player 1 wins")
              ((and (= player1-move "Paper") (= player2-move "Rock")) "Player 1 wins")
              "Player 2 wins")))
  )

(create-table games)
