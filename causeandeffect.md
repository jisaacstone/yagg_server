# clarifying cause and effect

The `Finally Finish Something` release of YAGG caused confusion. I observed others playing, and I noticed frequently they did not know what was going on, exactly.
I would get confused myself, and I built the game!

First, let's look into why we were all getttting confused. Then I will describe my solution.

## actions and updates

To understand what is causing the confusion let us simplify the game. There are two players, and they take turns performing actions (move, attack, etc).
The player's action is sent to the game's server, and the server sends updates to all players.

(img)

A player moves a unit, and the unit moves. Nobody is confused. So far so good.

## abilities and triggers

But we are not playing checkers! Uniqe abilities and triggers for each unit create situations where a single action can create a chain of consequences.
For example you opponent may use a `rowburn` ability to destroy your `explody`, which has a death trigger to explode, and the explosion kills your monarch.

(img)

What you opponent will experience in the current version of YAGG is confusion. Nobody is near your monarch, then a bunch of units die and you lose. What happened?

## show cause, then effect

The solution is to explicity send `causal` events.
Before we had a single action leading to many efffects.
Now we have an action followed by direct effects and explicit cause and effect chains.

Our example above now looks like this

(img)

Adding in a short pause to hilight the cause in our ui leads to much more clarity.

(webm)

## going forward

I hope this update eliminates the biggest causes of confusion. But some other causes remain unaddressed.

1. If an opponent's action is not visible to you, for example they moved an invisible unit, then the fact that it is your turn again may be missed.

2. If a browser crases or you miss and update for some reason, you will also miss the cause and effect indications.

Having a log of recent actions and updates will solve both these problems. I am working on a design for this.
