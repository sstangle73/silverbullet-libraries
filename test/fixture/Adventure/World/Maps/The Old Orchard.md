---
type: map
---

# The Old Orchard

The clearing at the middle of the old orchard, where the party has [its first fight](<../../Campaign/Act I/Scene 3>).

${maps.draw()}

A rough square of bare ground with the strangler rooted in the middle of it, and the creepers half-buried around the edge. The way back and the way on are the two gaps in the briar.

```map
#####^##
#,,,,,,#
#,c,,c,#
#,,S,,,#
#,,,,,,#
#,c,,c,#
#,,,,,,#
##v#####

grow to ${party.value{"square", plus = 3}}

# wall briar, ten feet high
, rough bramble and root - difficult terrain
^ exit the way on
v exit the way back
S token strangler = World/Monsters/Strangler
c token creeper = World/Monsters/Creeper
```
