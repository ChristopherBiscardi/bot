FROM biscarch/ghc-7.8.3

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install zlib1g-dev

ENV LANG en_US.utf8

RUN cabal update

ADD ./server $HOME/server
RUN cd $HOME/server && cabal install --only-dependencies

RUN cd $HOME/server && cabal install