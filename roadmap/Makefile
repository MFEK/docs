.PHONY: all
all:
	make timestamp roadmap.png

ODATE := $(shell eval date -Ru)
POINTSIZE := 48

.PHONY: timestamp
timestamp:
	echo "$(ODATE)" > .timestamp

roadmap.png: graph.dot timestamp
	dot -Gdpi=144 -Tpng < graph.dot > graph.png
	convert graph.png -font "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf" -pointsize $(POINTSIZE) -gravity SouthWest -stroke '#3c3c3c' -strokewidth 5 -annotate +5+5 "$(ODATE)" -stroke none -fill "#cfc" -annotate +5+5 "$(ODATE)" graph_date.png
	mv graph_date.png roadmap.png
	rm graph.png

roadmap.svg: graph.dot
	dot -Tsvg < graph.dot > roadmap.svg
