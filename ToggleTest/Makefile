PROJ=toggle_test
TRELLIS?=/usr/share/trellis

all: ${PROJ}.bit

%.json: %.v
	yosys -p "synth_ecp5 -json $@ -top toggle_test" $< ecppll.v

%_out.config: %.json
	nextpnr-ecp5 --pre-pack clk_constraint.py --json $< --textcfg $@ --um5g-85k --package CABGA381 --lpf ecp5.lpf

%.bit: %_out.config
	ecppack --svf ${PROJ}.svf $< $@

${PROJ}.svf : ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"

clean:
	rm -f *.svf *.bit *.config *.json make.log
