.PHONY: clean
clean:
	rm -rf bundle gvisor-logs
	sudo rm -f /etc/systemd/system/gvisor-hello.service
	sudo systemctl daemon-reload

bundle/rootfs:
	mkdir -p bundle/rootfs
	docker export $(shell docker create hello-world) | tar -xf - -C bundle/rootfs

bundle/config.json:
	mkdir -p bundle
	/usr/local/bin/runsc spec --bundle bundle/ -- /hello

bundle: bundle/rootfs bundle/config.json

.PHONY: service
service:
	PWD=$(shell pwd)
	cat gvisor-hello.service.tpl | sed -e "s|PWD|$(PWD)|g" > gvisor-hello.service
	sudo cp gvisor-hello.service /etc/systemd/system/gvisor-hello.service
	sudo chmod 644 /etc/systemd/system/gvisor-hello.service
	sudo systemctl daemon-reload

.PHONY: run
run: bundle service
	sudo systemctl start gvisor-hello.service
	USER=$(shell whoami)
	sudo chown $(USER) -R ./gvisor-logs

.PHONY: journal
journal:
	journalctl -u gvisor-hello.service -e
