FROM biscarch/ghc-7.8.3

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install zlib1g-dev libssl-dev -y
#RUN apt-get install git -y

ENV LANG en_US.utf8

RUN cabal update

# Include Dev webhooks types
RUN echo "redo webhooks pull"
RUN git clone https://github.com/ChristopherBiscardi/webhooks.git $HOME/webhooks
#ADD ./webhooks $HOME/webhooks
#RUN cd $HOME/webhooks && cabal install
# END Dev webhooks types

ADD ./server/bot.cabal $HOME/server/bot.cabal

RUN cd $HOME/server && cabal sandbox init && cabal sandbox add-source $HOME/webhooks

# HACKAGE DOWN!! HACKAGE DOWN!!
RUN sed 's/remote-repo:.*/remote-repo: hackage.fpcomplete.com:http:\/\/hackage.fpcomplete.com\//' ~/.cabal/config
RUN cd $HOME/server && cabal install --only-dependencies -v3 -j4

ADD ./server $HOME/server
RUN cd $HOME/server && cabal install

#CMD ["/root/.cabal/bin/bot","--no-access-log","--no-error-log"]
CMD ["/root/server/.cabal-sandbox/bin/bot","--no-access-log","--no-error-log"]
