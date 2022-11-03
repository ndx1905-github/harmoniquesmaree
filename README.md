# harmoniques maree
Créer les fichiers de prédiction de marée à partir des hauteurs d'eau - IMPROPRE A LA NAVIGATION


*Testé sur Ubuntu*
*Installer les éléments ci-après dans le dossier HOME*

#### CONGEN
```
cd
wget https://flaterco.com/files/xtide/congen-1.7-r2.tar.xz
tar -xf congen-1.7-r2.tar.xz
cd congen-1.7
./configure
make
sudo make install

```

#### OCTAVE

```
sudo apt install octave
```

#### HARMGEN

```
cd
wget https://flaterco.com/files/xtide/harmgen-3.1.3.tar.xz
tar -xf harmgen-3.1.3.tar.xz
cd harmgen-3.1.3
./configure
make
sudo make install
```

#### POSTGRESQL

```
sudo apt install postgresql postgresql-server-dev-all libecpg-dev # pour avoir sqlca.h
```


#### LIBTCD
```
cd 
wget https://flaterco.com/files/xtide/libtcd-2.2.7-r3.tar.xz
tar -xf libtcd-2.2.7-r3.tar.xz
cd libtcd-2.2.7
./configure
make
sudo make install
```


#### LIBDSTR
```
cd
wget https://flaterco.com/files/libdstr-1.0.tar.bz2
tar -xf libdstr-1.0.tar.bz2
cd libdstr-1.0
./configure
make
sudo make install
```

#### HARMBASE2
```
cd
wget https://flaterco.com/files/xtide/harmbase2-20220109.tar.xz
tar -xf harmbase2-20220109.tar.xz
cd harmbase2-20220109
./configure CPPFLAGS=-I/usr/include/postgresql 
make
sudo make install
```
#### TCD-UTILS
```
cd
wget https://flaterco.com/files/xtide/tcd-utils-20120115.tar.bz2
tar -xf tcd-utils-20120115.tar.bz2
cd tcd-utils-20120115
./configure
make
sudo make install
```
#### STRUCTURE DOSSIER
```
cd
mkdir data
cd data
mkdir maregraphie
mkdir arduino_libraries


