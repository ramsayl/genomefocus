#Edit prefix, full path to exe files, and number of threads. 
#Run via "make -f"

PREFIX=smartdenovo-k23

EXE_PRE=wtpre
EXE_ZMO=wtzmo
EXE_OBT=wtobt
EXE_GBO=wtgbo
EXE_CLP=wtclp
EXE_LAY=wtlay
EXE_CNS=wtcns
N_THREADS=120

all:$(PREFIX).dmo.lay

$(PREFIX).fa.gz:
	$(EXE_PRE) -J 5000 ../../sequences/raw-sequences.fa | gzip -c -1 > $@

$(PREFIX).dmo.ovl:$(PREFIX).fa.gz
	$(EXE_ZMO) -t $(N_THREADS) -i $(PREFIX).fa.gz -fo $@ -k 23 -z 10 -Z 16 -U -1 -m 0.1 -A 1000

$(PREFIX).dmo.obt:$(PREFIX).fa.gz $(PREFIX).dmo.ovl
	$(EXE_CLP) -i $(PREFIX).dmo.ovl -fo $@ -d 3 -k 300 -m 0.1 -FT

$(PREFIX).dmo.lay:$(PREFIX).fa.gz $(PREFIX).dmo.obt $(PREFIX).dmo.ovl
	$(EXE_LAY) -i $(PREFIX).fa.gz -b $(PREFIX).dmo.obt -j $(PREFIX).dmo.ovl -fo $(PREFIX).dmo.lay -w 300 -s 200 -m 0.1 -r 0.95 -c 1

