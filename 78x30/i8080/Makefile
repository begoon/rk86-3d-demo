all: generate build inject

IMAGE=rk86demo

build:
	asm8080 -l$(IMAGE).lst $(IMAGE).asm

load:
	rk86load $(IMAGE).hex

run:
	CMD="go 0000" rk86load

clean:
	-rm $(IMAGE).hex $(IMAGE).bin $(IMAGE).lst frames.asm
	$(MAKE) -C generator clean
	$(MAKE) -C rk86js clean
	$(MAKE) -C pure clean

generate:
	$(MAKE) -C generator
	cp generator/frames.asm .

inject:
	cp $(IMAGE).bin rk86js/files/
	(cd rk86js && make)

view:
	open rk86js/radio86.html

