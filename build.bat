64tass -a ./src/mus-player.asm -l ./target/mus-player.lbl -L ./target/mus-player.lst -o ./target/mus-player
64tass -a -b ./src/mus-player-crt.asm -o  ./target/mus-player-crt.bin

c1541 -format "mus-player,sh" d64 ./target/mus-player.d64
c1541 -attach ./target/mus-player.d64 -write ./target/mus-player mus-player
c1541 -attach ./target/mus-player.d64 -write ./target/ghostbusters.mus ghostbusters.mus
