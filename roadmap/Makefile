.PHONY: all
all:
	make timestamp roadmap.png

ODATE := $(shell eval date -Ru)
POINTSIZE := 24

.PHONY: timestamp
timestamp:
	echo "$(ODATE)" > .timestamp

roadmap.png: graph.dot timestamp
	dot -Tpng < graph.dot > graph.png
	convert graph.png -font DejaVu-Sans-Mono-Book -pointsize $(POINTSIZE) -gravity SouthWest -stroke '#3c3c3c' -strokewidth 5 -annotate +5+5 "$(ODATE)" -stroke none -fill "#cfc" -annotate +5+5 "$(ODATE)" graph_date.png
	mv graph_date.png roadmap.png
	rm graph.png

roadmap.svg: graph.dot
	dot -Tsvg < graph.dot > roadmap.svg
