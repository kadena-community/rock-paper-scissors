# Using Formal Verification to specify your Smart Contract

## Introduce Formal Verification

Definition of Formal Verification on wikipedia:

> In the context of hardware and software systems, formal verification is the
> act of proving or disproving the correctness of intended algorithms underlying
> a system with respect to a certain formal specification or property, using
> formal methods of mathematics.

This can seem pretty daunting, I know it did for me. It feels like a very
complicated system, that is out of reach for many developers. After using
Formal Verification for a couple of months, I've changed my mind and with the
steady stream of updates on the Formal Verification modules, I think it
is a very strong asset any developer developing smart contracts should
leverage.

## Why should we write Formal Verification

Formal Verification allows you to specify the expected behaviors of your smart contract.
You could specify your smart contract before you implement any logic. Allowing
you to identify challenges upfront and come up with high level solutions. This
way of thinking you to zoom in on a specific detail, while ignoring all other aspects.

For example, I can zoom in on a single win condition of a game of Rock, Paper, Scissors,
while ignoring all the other win conditions. All I specify is, that single win condition.
Then I can proceed to specify the next win condition and so on. Like this, I know that
if my smart contract can be Formal Verified, it satisfies all conditions without
writing unit tests for all those use cases.

## Introduce our usecase

Let's create a smart contract that will govern a game of Rock, Paper, Scissors.
Normally when you play in real life, both players are agreeing to reveal their
move at the same time.

In a traditional web 2 application, both players could submit their move to an
centralized server. If this centralized server for some reason is compromised,
it could lead to some unfair advantage of either player.

Due to the decentralized nature of the blockchain, we are taught to distrust any
involved party. A way to provide a fair process that can be trusted, without trusting
the involved parties, could be to commit your move in the first step and reveal
your move in the second step.

In this mini guide, we will show how Formal Verification can help guide us
through the process of defining a Smart Contract.

## Define interface

We start off by defining a smart contract, `rps.pact` with the
following content.

```clojure
(module rock-paper-scissors GOVERNANCE
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
    0)

  )
```

This scaffolds our initial interface, where we have a `rock-paper-scissors`
module containing two functions, `commit` and `reveal`.

We can prepare a test file that will act as our playground, `rps.repl` with
the following contents:

```clojure
(begin-tx)
(load "rps-1.pact")
(commit-tx)

(verify "rock-paper-scissors")
```

This loads our smart contract into our test environment and performs a
verification of the defined model, once defined. Our current contract
does not contain any model definition, so it doesn't do much yet.

## Specify your expectations

Now we can start specifying our model for our game. First let's specify
what the valid moves are. We can first define a `reusable` property
`is-valid-move`. This property simply checks if the provided move
is either `rock`, `paper` or `scissors`, returning `true` if valid
and `false` if invalid.

```clojure
(module rock-paper-scissors GOVERNANCE
  @model [
    (defproperty is-valid-move(move:string)
      (or (= move "rock")
          (or (= move "paper") (= move "scissors"))))
  ]
```

Now we can specify the moves provided in the `reveal` function:

```clojure
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
```

Now if we would run the `rps.repl` it will validate the smart contract and
produce the following error:

```sh
rps.pact:24:16:OutputFailure: Invalidating model found in rock-paper-scissors.reveal
  Program trace:
    entering function rock-paper-scissors.reveal with arguments
      id = ""
      player1-move = ""
      player1-salt = ""
      player2-move = ""
      player2-salt = ""

      returning with 0


rps.pact:25:16:OutputFailure: Invalidating model found in rock-paper-scissors.reveal
  Program trace:
    entering function rock-paper-scissors.reveal with arguments
      id = ""
      player1-move = ""
      player1-salt = ""
      player2-move = ""
      player2-salt = ""

      returning with 0


Load successful
```

It outputs notifies about two invalidating models and provides the input
used to reach this state, along with the result it produced. In general
when your model is invalidated, you'd expect the transaction to fail.
This is how we know if we have guarded our smart contract enough once
implemented.

Now we can specify win, lose and draw conditions. For simplicity sake
I'll be specifying from player one's perspective. The `result` keyword
refers to what the function will output. Note that we have defined
3 different possible outcomes: `Player 1 wins`, `Player 2 wins` or `Draw`.

```clojure
(module rock-paper-scissors GOVERNANCE
  @model [
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
```

Now we can use these properties to specify how our `reveal` function
should behave. As the result is now specified to be a string of either
`Player 1 wins`, `Player 2 wins` or `Draw`, we need to update the return
value to match accordingly.

```clojure
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
```

Formal Verification still has some limitations. We are not able to
specify behaviors around the `hash` function. We want to specify how
a move is committed by specifying how it can be revealed. To work around
this limitation, we will make use of the `expect-failure` in the `.repl`
environment.

In this example, we want the player to submit a hash of their move concatenated with
a random string. When revealing, they will provide both their move and the random
string in order to reproduce the hashed string. This will be proof that their
revelation is thruthfull.

```clojure
(begin-tx)
(load "rps-4.pact")
(commit-tx)

(verify "rock-paper-scissors")

(begin-tx)
(rock-paper-scissors.commit
  "game-1"
  "alice"
  "bob"
  (hash "rock-a-salt-that-should-be-random")
  (hash "rock-a-different-salt-that-is-random"))
(commit-tx)

(begin-tx)
(expect-failure
  "Expect player one's move to be incorrect"
  "Player 1 revealed move does not match saved move"
  (rock-paper-scissors.reveal
    "game-1"
    "rock"
    "incorrect-salt"
    "rock"
    "a-different-salt-that-is-random"))
(commit-tx)

(begin-tx)
(expect-failure
  "Expect player two's move to be incorrect"
  "Player 2 revealed move does not match saved move"
  (rock-paper-scissors.reveal
    "game-1"
    "rock"
    "a-salt-that-should-be-random"
    "rock"
    "incorrect-salt"))
(commit-tx)
```

## Implement your contract

Now we have all our expectations in place, we can start implementing
our contract. We know if we haven't missed any use case when all
tests are passing.

As we have specified that the move has to be be committed and revealed
in two steps, we need a table to store the committed move.

```clojure
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
```

Now we can compare the submitted move with the revealed move and validate
if no player is dishonest.

```clojure
  (defun enforce-valid-move(move:string)
    (enforce
      (or (= move "rock")
      (or (= move "paper") (= move "scissors")))

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
```

By using enforce statements, we can guard our function from any illigit
entry. First of all we guard the function from processing any move
that does not match the committed move. Since the move committed
is not revealed up until now, we need to make sure that the move is
valid to begin with.

Now that we know that the moves are good to go, we can determine the result.
By using `cond` we can specify a list of `Draw` and `Win` conditions. Once
implemented, we can rerun the `.repl` and verify if we have satisfied our
specifications.

_Note: OutputWarnings will be displayed, due to the usage of `hash`. This is_
_to warn developers of the substitutation of the hash function inside of_
_the formal verification context._

After cleaning up our code and redefining the moves as constants we end up with the following contract:

```
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
```

## Conclusion

By specifying our desired outcome, we could without keeping the entire picture
in mind, define our game. A game of Rock Paper Scissors, is still relatively
easy to grasp, expand the game to have more options, and it get's increasingly
difficult to keep all details in mind. With Formal Verification, this task, stays
simple. All that happens is that the specification will grow, but reasoning
about the specification, remains simple.
