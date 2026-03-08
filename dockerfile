FROM sharelatex/sharelatex:6.1.1
RUN tlmgr update --self && tlmgr install scheme-full
# docker build -t sharelatex/sharelatex:6.1.1 .