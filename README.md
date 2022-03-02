# batless-barry-bonds
Revisiting the Jon Bois video on Barry Bonds without a bat, but without simulation. Using an expected value calculation method, I determine that Barry Bonds could have an OBP of 0.598 (without rounding, 0.5984841).

To run my code so you know it works:
- Download batless-barry-bonds.R from the github link above
- Download the 2004 regular season Retrosheet event file here - it will download as a .zip: https://www.retrosheet.org/game.htm
- Export all the files from the .zip into a folder, preferably a top-level directory called "Retrosheet" but you could put it wherever
- Open up R or R Studio, modify the code to set the working directory to wherever you put the retrosheet files, and run batless-barry-bonds.R
- After literally hundreds of thousands of parsing failures (it's fine don't worry) and 5-10 minutes, you will have the same results


-----

FULL EXPLANATION

INTRODUCTION

You're probably familiar with the Jon Bois video "What if Barry Bonds had played without a baseball bat?" - if you haven't, it's great, you should watch it! You can watch it here: https://www.youtube.com/watch?v=JwMfT2cZGHg 

If you haven't watched it and don't have time to, here's a quick summary:

- Jon takes every 2004 at-bat for Bonds, and “takes away his bat” - meaning the same pitches get thrown at him, Barry just can’t hit any of them. Walks are still walks, strikes are still strikes, if he gets hit by a pitch he still gets beaned, but hits (including fouls) become either walks or strikes.
- Jon introduces his methodology: He uses data from Retrosheet, which tracks the outcome of each pitch. In cases where not having a bat leads to more pitches than there were in real life, Jon simulates the pitch by drawing from the average of pitches that season. For example, 19.1% of the fouls Bonds hit were within the strike zone, so if the foul would’ve affected the outcome, Jon generates a random number between 1 and 1000, and anything above 191 counts the at-bat as a strike.
- Jon reveals the results: Even without a bat, Bonds would still have had an OBP of 0.608 in 2004, still the best in baseball history.

He mentions at the end of the video that re-simulating may have given him a different result. A couple of other people have tried to tackle this already.
- Reddit user /u/cg2916 ran the simulation 30 times and got an OBP of 0.5871, but only on Bond's home plate appearances: https://www.reddit.com/r/Jon_Bois/comments/96ek89/barry_bonds_without_a_bat_revisited_looks_like/
- Nick Sun ran the simulation, plus another similar simulation using antithetic variables, and got average OBPs around .592: http://www.nicksun.fun/ds/2021/03/27/bonds.html

I’ve been a massive fan of Jon Bois for years, but this video has always irked me. I have always wondered: Why did he simulate the pitches? Could we solve this problem without simulation?

I have a statistics minor and some proficiency in R, so I am the most qualified person to solve this problem.

METHODOLOGY

We're trying to find the expected value of Bond's OBP given that the following assumptions are true (percentages taken from Bois's video):
- All pitches Bonds swung at were in the strike zone 80.9% of the time and outside 19.1% of the time
- All pitches thrown at Bonds, regardless of outcome, pitcher or surrounding pitches, were in the strike zone 41.3% of the time and out 58.7%, and that this would be true if more pitches were thrown at Bonds

I have written a script that takes Retrosheet's 2004 event files, isolates every Barry Bonds plate appearance (home or away), and cleans the data so that every pitch result is either a ball, strike, hit by pitch, hit, or foul. I'll note these five results as follows, in line with Retrosheet pitch notation:
- Ball - B
- Strike - C (Retrosheet's notation for a called strike, the most common type)
- Hit by pitch - H
- Hit - X
- Foul - F

Each plate appearance has its own row. Bonds has other results like foul tips (T), swinging strikes (S), etc that we'll coerce into being one of the five types above.

I will analyze each plate appearance based on normal baseball rules. If we get 3 strikes, we assign what I’m calling an earned-base-value (EBV) of 0 since he didn’t get on base, and 4 balls get an EBV of 1 since he did get on base, one time. We'll always have a result within 7 pitches, so we only need to analyze the first 7 pitches thrown.

If Bonds got hit by a pitch, the plate appearance gets an EBV of 1. None of his 9 HBP outcomes would’ve been changed if he didn’t have a bat. 

What happens when we get to a foul? Take, for example, this fucking nightmare of a plate appearance from the real data: BFFFBBFFFFX. We don’t have to deal with all of this - we’re going to get a result of 3 balls or 4 strikes in 7 pitches. So, BFFFBBF. 

My thought is to replace the original row with two rows:
- BCFFBBF, and we multiply the EBV by 0.809
- BBFFBBF, and we multiply the EBV by 0.191

Then each of those with two more rows with the same rules, and so on until we're out of fouls.

When the script processes a hit, we'll do something similar. We'll start by splitting an EBV split of 0.809 (replacing the hit with a strike in this appearance) and 0.191 (replacing the hit with a ball). Then, if we're not already at 7 pitches, we'll split the appearance using EBV values of 0.413 (strike) and 0.587 (ball). We can actually run this last simulation on all empty cells - if our system processes each pitch in order, it will process a plate appearance that starts with four balls as a walk whether it's BBBBBBB or BBBBCCC.

Once we've split up every plate appearance into 7 strikes or balls and miniscule EBVs, we'll count up the number of strikes and balls in each appearance in order. If we get to 4 balls, we'll leave the EBV for that appearance alone and move on to the next appearance. If we get to 3 strikes, we'll multiply the EBV by 0 and move onto the next appearance.

Eventually, we'll be out of appearances. Then we'll sum the EBVs, divide by the total number of plate appearances Bond made in 2004 (which happens to be 613), and we'll have a final, non-simulated batless OBP.

RESULTS & RECREATION: 

Without a bat, Barry gets a single-season OBP of 0.598484 in 2004. Still the best in baseball history, but a smidge behind his real-life numbers.

FAQ:

- Yes, I did run sum(sheet$EBV) after each row_applier() to make sure that the EBVs were still adding up to 613 before it went into the ball/strike counter. They do, don’t worry. You can modify the code to do this yourself if you'd like to double-check.
- Yes, my code is extremely hacky. Yes, I know I shouldn't use for loops in R. The final product took like five minutes to run and now my laptop smells a little like burnt plastic. Please note that I do not take constructive criticism, only compliments.
- You could generalize this out into being generic for any player with some tweaks, but I’m not going to. Maybe someday.
- Yes, I do have a girlfriend. Her review of this experiment was that it is “totally sick and has totally sick results” but that if I “explained it to her step by step she would ask me to stop”.
