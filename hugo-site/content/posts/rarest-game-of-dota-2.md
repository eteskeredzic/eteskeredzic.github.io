---
title: "What is the rarest game of DotA2?"
date: 2026-01-28
description: "A combinatorics problem hiding inside 3.5 million matches."
tags:
  [
    "tech",
    "dota 2",
    "combinatorics",
    "data analysis",
    "gaming",
    "python",
    "mathematics",
  ]
ShowToc: true
math: true
ShowPostNavLinks: false
---

![Cover image](/posts/rarest-game-of-dota-2/cover.png)

For a long time, one of my favorite hobbies was gaming, and one of my favorite games was DotA 2. According to Steam, I've spent thousands of hours playing it - and whether alone or with friends, I always had a blast!

The premise of the game is deceptively simple: Two teams of 5 players, each controlling a hero, need to defend their base (so-called Ancient), while at the same time trying to destroy the enemy base. That's the basic idea - you now understand the game. But, given over a hundred heroes, items, play-styles, etc., DotA is actually extremely complex, and virtually no two games are the same. It's easy to understand, but hard to master - kinda like chess.

On the topic of chess, I have recently watched a great video titled _The rarest move in chess_ {{< sidenote >}}[The rarest move in chess (video by Paralogical)](https://www.youtube.com/watch?v=iDnW0WiCqNc){{< /sidenote >}}. It's a fascinating exploration of chess games documented online. So, if we can ask _What is the rarest move in chess?_, then naturally...

{{< centered-quote >}}
What is the rarest game of DotA 2?
{{< /centered-quote >}}

Since this question cannot be answered without both combinatorics AND programming, I decided to find out!

## A game of infinite variety

There are some caveats to this question, namely:

- We can only analyze games that have been documented online. To do that, I'll need a dataset of DotA 2 matches - the larger the better.
- A game of DotA 2 has many parameters - hero picks, item builds, player positions, etc. In order to keep things manageable, I will only consider hero picks. This means that two games are the same if the same heroes have been picked by the same teams (so side/team matters!). In addition, the sides in DotA are not symmetrical, so I'm treating drafts where some (or all) heroes are swapped between sides as different drafts.

I'll look into these two points in more detail.

### Getting game data

Fortunately, there's a great project called OpenDota{{< sidenote >}}[OpenDota project](https://www.opendota.com/){{< /sidenote >}}, which provides open-source data on DotA 2 matches. The folks maintaining the project have released two comprehensive data dumps: one from 2015{{< sidenote >}}[December 2015 Data Dump](https://blog.opendota.com/2015/12/20/datadump/){{< /sidenote >}}, containing 3.5 million matches, and another one from 2017{{< sidenote >}}[Data Dump (March 2011 to March 2016)](https://blog.opendota.com/2017/03/24/datadump2/){{< /sidenote >}}, with over a billion matches.

The bigger dataset is not available (the data is no longer being seeded via torrents), so the smaller one will have to do (at least for now). It's available as a gzipped JSON file (~100 GB). The structure of this JSON file is described on the OpenDota Github page{{< sidenote >}}[OpenDota GitHub Repository - JSON Data Dump description](https://github.com/odota/core/wiki/JSON-Data-Dump){{< /sidenote >}}.

After downloading the data dump, I used Python to parse through the data in a streaming fashion (you really want to stream data for datasets this big - have you seen these RAM prices?). The only relevant information for this little experiment are the hero drafts, so I've disregarded all other data. What I ended up with was a NDJSON file containing 3 566 804 drafts.

Here's the script that handles the streaming+parsing of the data (for brevity, error handling has been omitted). The following code reads the JSON, and outputs the relevant draft data for every match, in NDJSON format:

```python
#!/usr/bin/env python3
import sys
import json
import ijson
from tqdm import tqdm


def main() -> None:
    """
    Streams through JSON array; outputs relevant match data as NDJSON.
    Data to output for every match:
    - match_id
    - game_mode
    - players: list of dicts with hero_id and player_slot
    """
    items = ijson.items(sys.stdin, "item")

    for m in tqdm(items, unit="matches", mininterval=25.0):
        match_id = m.get("match_id")
        game_mode = m.get("game_mode")
        players = m.get("players") or []

        out_players = []
        for p in players:
            hero_id = p.get("hero_id")
            player_slot = p.get("player_slot")
            out_players.append(
                {
                    "hero_id": hero_id,
                    "player_slot": player_slot,
                }
            )

        out = {
            "match_id": match_id,
            "game_mode": game_mode,
            "players": out_players,
        }
        sys.stdout.write(json.dumps(out, separators=(",", ":"))+"\n")


if __name__ == "__main__":
    main()
# invoke script with:
# gzcat yasp-dump.json.gz | python3 main.py > matches.ndjson
```

Now I have an NDJSON file (around 1.32 GB) containing the drafts. For every match, I have the match ID, game mode, and the hero picks for both teams (player team is indicated by `player_slot`).

{{< note-box >}}

**_Note:_** While this dataset is great, it does have one glaring issue - 3.5 million matches is relatively small compared to the actual number of DotA 2 games played since the game's release (8.6 billion). Many drafts that have been played in the wild are most likely not included in this dataset. However, as we'll see later, even with a hypothetical perfect dataset, we have not even scratched the surface of all possible drafts.

{{< /note-box >}}

Before looking at this data though, there's a fundamental question that needs to be answered: How many different drafts are even possible?

### A brief detour into combinatorics

I'm only looking into hero picks, so I can calculate the number of possible hero drafts for each team. In a standard game, the teams (Dire and Radiant) each pick 5 heroes from a pool of heroes. The order does not matter, and a hero can only be picked once.

In combinatorics, the number of ways to choose _k_ elements from a set of _n_ elements is given by the binomial coefficient, often read as "n choose k". The formula is quite simple:

{{< centered-quote >}}
$${n \choose k} = \frac{n!}{k! * (n - k)!}$$
{{< /centered-quote >}}

Since our dataset is from December of 2015, the hero pool (n) consists of 111 heroes. So the number of possible 10-hero drafts is:
{{< centered-quote >}}
$${111 \choose 10} = 51\ 540\ 966\ 982\ 791$$
{{< /centered-quote >}}

...or **51 trillion 540 billion 966 million 982 thousand 791** possible drafts! But hold up - that's just the number of ways to pick 10 heroes. This calculation does not take into account which team picked which heroes. So, our actual formula is:

{{< centered-quote >}}
$${111 \choose 5} * {106 \choose 5} = 12\ 988\ 323\ 679\ 663\ 332$$
{{< /centered-quote >}}

{{< centered-quote >}}
...or...
{{< /centered-quote >}}

{{< centered-quote >}}
**12 quadrillion 988 trillion 323 billion 679 million 663 thousand 332 possible drafts!**
{{< /centered-quote >}}

That number is just absurdly large. To put things into perspective, if we started 100 games of DotA 2 every second, we would need a little over 4.1 million years in order to play through every possible draft. Furthermore, with every new hero added to the game, this number grows larger - not linearly, but combinatorially!

Another way to grasp this number is to compare it to the actual amount of DotA 2 games played. As of writing this article, there have been approximately 8.6 billion matches played (this number also includes silly game modes like ability draft). DotA 2 released in 2013, so with this amount of games in 13 years, we will need another 20 million years before we reach this number!

This is great news! Since only a tiny fraction of all possible drafts has been played, there must be drafts that have never (and will never) be played. Which implies a rarest game of DotA 2 exists!

## Finding the rarest game

The data is ready, and I know for certain that not all possible drafts have been played. I can now find the rarest game of DotA 2!

Since the data has been nicely parsed, this is not that hard. I've written a simple Python script that streams through our NDJSON, and counts the occurences of each draft, using the neat built-in `Counter` class that Python offers. I expect the number of unique drafts to be far smaller than 3.5 million - this fits neatly into memory - for larger datasets, solutions like DuckDB or SQLite can help.

First, I extract the drafts from the dataset, returning them as two tuples of 5 elements each (the hero IDs - which are constant over time and never change) - the tuples have been sorted, so the ordering inside a specific team does not matter.

The following function handles the described draft extraction:

```python
def extract_draft(match: dict) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    """
    Return the draft of a match as two sorted tuples (Radiant, Dire).
    If the match does not have a complete 5v5 draft, return None.
    Radiant is identified by player_slot 0-4, Dire by 128-132.
    """
    players: list[dict] = match.get("players", [])
    radiant_heroes = []
    dire_heroes = []

    for player in players:
        hero_id = player.get("hero_id")
        slot = player.get("player_slot", 0)

        if hero_id is None or hero_id == 0:
            continue

        # Slots 0-4 are Radiant, 128-132 are Dire
        if slot < 128:
            radiant_heroes.append(hero_id)
        else:
            dire_heroes.append(hero_id)

    # Only return complete 5v5 drafts
    if len(radiant_heroes) == 5 and len(dire_heroes) == 5:
        return (
            tuple(sorted(radiant_heroes)),
            tuple(sorted(dire_heroes)),
        )

    return None
```

The two tuples (well, tuple of tuples) can now be used as the key for the `Counter`. Let's open the NDJSON file, stream it line by line (that's the beauty of NDJSON), extract the draft, and just attach it to our counter. Also, the code keeps track of the match ID, so that I can access the specific matches of interest later on.

I wrote a function that does just that:

```python
def parse_matches(filepath: Path,) -> tuple[Counter, dict]:
    """
    Parses the NDJSON file line-by-line,
    and counts the occurences of each draft.
    Returns a Counter of drafts and
    a dict mapping drafts to match IDs.
    """
    draft_counter: Counter[tuple] = Counter()

    draft_match_ids: dict[tuple, int] = {}

    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()

            match: dict = json.loads(line)
            draft = extract_draft(match)
            if draft is not None:
                draft_counter[draft] += 1
                if draft not in draft_match_ids:
                    draft_match_ids[draft] = match.get("match_id", 0)

    return draft_counter, draft_match_ids
```

After some additional code to parse the results, we have our answer:

{{< centered-quote >}}
The rarest draft in our dataset has been played only once and it is...drumroll please... 🥁🥁🥁
{{< /centered-quote >}}

...actually, there's a whole bunch of them. This should not be surprising for those who have followed along on the combinatorics part. The number of possible drafts is practically infinitely larger than what is available in the dataset. In fact, out of 3.5 million matches, 3 550 920 of them have drafts that occur only once in the dataset (which is around 99.6%).

Here's one of the drafts that has been played only once:

![One of the rarest drafts found in the dataset (played only once)](/posts/rarest-game-of-dota-2/rarest_draft.png)

This match has the ID `2001385642`, and you can actually check it out on Dotabuff: [https://www.dotabuff.com/matches/2001385642](https://www.dotabuff.com/matches/2001385642)

Considering the draft, it's no wonder that Dire stomped this game after only 28 minutes of playtime.

Here's the same stats, for two game modes specifically: All Pick and Ranked Competitive. I've also included the **most common draft**:

| Game Mode | Valid 5v5 drafts | Unique drafts | Drafts appearing exactly once | Most common draft (occurences) |
| --------- | ---------------- | ------------- | ----------------------------- | ------------------------------ |
| All Pick  | 1 525 451        | 1 525 357     | 1 525 326                     | 31                             |
| Ranked    | 1 547 377        | 1 547 375     | 1 547 373                     | 2                              |

The most common draft in All Pick consists of the following lineup:

- **Radiant:** Enigma, Beastmaster, Luna, Nature's Prophet, Huskar
- **Dire:** Morphling, Weaver, Keeper of the Light, Io, Medusa

For Ranked Competitive, the most common draft is (and I'm really glad to see my GOAT Pugna here):

- **Radiant:** Zeus, Warlock, Silencer, Troll Warlord, Bristleback
- **Dire:** Axe, Sniper, Pugna, Omniknight, Undying

## Future work

This was a fun excuse for me to talk about combinatorics! However, there's a lot more that can be done here:

- Analyze the larger dataset (>1 billion matches) if it becomes available again - if someone from OpenDota reads this, please reach out!
- Extract more fun insights from the dataset - what end-game item has been bought the most times? How many times has poor Roshan died? Longest game? Game with most kills? Player with highest cummulative stun duration? You get the idea.
- Visualize the distribution of draft frequencies: How many drafts have been played once, twice, etc.?

## Conclusion

Games like DotA 2 can be played for thousands of hours, not because they are random, but because of the mind-bogglingly large universe of possible games, so huge that even playing billions of matches barely explore it.

Realistically, because of things like win rates, meta-game, etc., you will see the same drafts multiple times when playing. However, even if you started playing now and kept at it all the way until the heat death of the Universe, you will never play every game.

{{< emphasized-quote >}}
So, what is the rarest game of DotA 2? Well, there are trillions, and they are waiting for you to play them!
{{< /emphasized-quote >}}

{{< references-section >}}

