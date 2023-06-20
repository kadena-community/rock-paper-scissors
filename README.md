# Using Formal Verification to specify your Smart Contract

## Introduce Formal Verification

## Why should we write Formal Verification

## Introduce our usecase

## Define interface

Explain rps-1.pact and rps-1.repl

## Specify your expectations

Explain the error produced after specifying valid moves:

```
rps-2.pact:24:16:OutputFailure: Invalidating model found in rock-paper-scissors.reveal
  Program trace:
    entering function rock-paper-scissors.reveal with arguments
      id = ""
      player1-move = ""
      player1-salt = ""
      player2-move = ""
      player2-salt = ""

      returning with 0


rps-2.pact:25:16:OutputFailure: Invalidating model found in rock-paper-scissors.reveal
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

Explain win, lose and draw conditions

Explain limitation of FV with `hash` and show `.repl` using `expect-failure` to cover
for that limitation.

## Implement your contract

## Conclusion
