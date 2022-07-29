# VA-11 Hall-A Tools

This is a collection of scripts and libraries written in Ruby which operate
on data files that come with _VA-11 Hall-A: Cyberpunk Bartender Action_. You
can extract multimedia data and more.

In theory, these tools could also work on other games created with Game
Maker Studio, but I don't have any games like that, and they're not my
focus. So, YMMV there.


## The tools!

- `va11halla_extract` -- parses the resource bundle (game.ios, data.win
  and/or data.unx) and lets you extract multimedia data from it

- `va11halla_reader` -- parses and tokenizes a dialogue script

- `va11halla_textmode` -- leverages the dialogue script parser to create a
  rudimentary console version of VA-11 Hall-A. It currently is not suitable
  to be a recreation of the game, since there's no logic handling nor
  anything else, really.
