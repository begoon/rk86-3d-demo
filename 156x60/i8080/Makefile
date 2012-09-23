all: build inject

IMAGE=rk86demo

build:
	asm8080 -l$(IMAGE).lst $(IMAGE).asm

load:
	rk86load $(IMAGE).hex

run:
	CMD="go 0000" rk86load

clean:
	-rm $(IMAGE).hex $(IMAGE).bin $(IMAGE).lst
	$(MAKE) -C rk86js clean

inject:
	cp $(IMAGE).bin rk86js/files/
	$(MAKE) -C rk86js
