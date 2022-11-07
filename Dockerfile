FROM gcc:10-buster

RUN apt-get update \
	&& apt-get install -y -f r-base; exit 0

RUN apt remove -y gfortran

RUN apt-get install -y octave gawk postgresql postgresql-server-dev-all libecpg-dev #pour avoir sqlca.h

RUN wget https://flaterco.com/files/xtide/libtcd-2.2.7-r3.tar.xz \
	&& tar -xf libtcd-2.2.7-r3.tar.xz \
	&& cd libtcd-2.2.7 \
	&& ./configure \
	&& make \
	&& make install

RUN wget https://flaterco.com/files/xtide/congen-1.7-r2.tar.xz \
	&& tar -xf congen-1.7-r2.tar.xz \
	&& cd congen-1.7 \
	&& ./configure \
	&& make \
	&& make install

RUN wget https://flaterco.com/files/xtide/tcd-utils-20120115.tar.bz2 \
	&& tar -xf tcd-utils-20120115.tar.bz2 \
	&& cd tcd-utils-20120115 \
	&& ./configure \
	&& make \
	&& make install	

RUN wget https://flaterco.com/files/libdstr-1.0.tar.bz2 \
	&& tar -xf libdstr-1.0.tar.bz2 \
	&& cd libdstr-1.0 \
	&& ./configure \
	&& make \
	&& make install

RUN wget https://flaterco.com/files/xtide/harmgen-3.1.3.tar.xz \
	&& tar -xf harmgen-3.1.3.tar.xz \
	&& cd harmgen-3.1.3 \
	&& ./configure \
	&& make \
	&& make install

RUN wget https://flaterco.com/files/xtide/harmbase2-20220109.tar.xz \
	&& tar -xf harmbase2-20220109.tar.xz \
	&& cd harmbase2-20220109 \
	&& ./configure CPPFLAGS=-I/usr/include/postgresql  \
	&& make \
	&& make install

RUN rm *.*z* \
	&& mkdir data \
	&& cd data \
	&& mkdir maregraphie \
	&& mkdir arduino_libraries

COPY read_harmonicsfile.R tide_harmonics_library_generator_multi.R tide_harmonics_parse.R wl2tide.sh /

ENTRYPOINT ["/wl2tide.sh"]