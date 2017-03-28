GOBUILDFLAGS += -ldflags -s

all:
	-mkdir -p bin
	cd kr; go build $(GOBUILDFLAGS) -o ../bin/kr
	cd krd/main; go build $(GOBUILDFLAGS) -o ../../bin/krd
	cd pkcs11shim; make; cp target/release/kr-pkcs11.so ../bin/
	cd krssh; go build $(GOBUILDFLAGS) -o ../bin/krssh


check:
	go test $(GOBUILDFLAGS) github.com/kryptco/kr github.com/kryptco/kr/krd github.com/kryptco/kr/krdclient github.com/kryptco/kr/kr github.com/kryptco/kr/krssh
	cd pkcs11shim; cargo test

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	PREFIX ?= /usr
	SUDO = sudo
endif
ifeq ($(UNAME_S),Darwin)
	PREFIX ?= /usr/local
endif

SRCBIN = $(PWD)/bin
DSTBIN = $(PREFIX)/bin
DSTLIB = $(PREFIX)/lib
install: all
	$(SUDO) ln -sf $(SRCBIN)/kr $(DSTBIN)/kr
	$(SUDO) ln -sf $(SRCBIN)/krd $(DSTBIN)/krd
	$(SUDO) ln -sf $(SRCBIN)/kr-pkcs11.so $(DSTLIB)/kr-pkcs11.so
	mkdir -p ~/.ssh
ifeq ($(UNAME_S),Darwin)
	perl -0777 -ne '/# Added by Kryptonite\nHost \*\n\tPKCS11Provider \/usr\/local\/lib\/kr-pkcs11.so\n\tProxyCommand `find \/usr\/local\/bin\/krssh 2>\/dev\/null \|\| which nc` %h %p\n\tIdentityFile ~\/.ssh\/id_kryptonite\n\tIdentityFile ~\/.ssh\/id_ed25519\n\tIdentityFile ~\/.ssh\/id_rsa\n\tIdentityFile ~\/.ssh\/id_ecdsa\n\tIdentityFile ~\/.ssh\/id_dsa/ || exit(1)' ~/.ssh/config || echo '\n# Added by Kryptonite\nHost *\n\tPKCS11Provider /usr/local/lib/kr-pkcs11.so\n\tProxyCommand `find /usr/local/bin/krssh 2>/dev/null || which nc` %h %p\n\tIdentityFile ~/.ssh/id_kryptonite\n\tIdentityFile ~/.ssh/id_ed25519\n\tIdentityFile ~/.ssh/id_rsa\n\tIdentityFile ~/.ssh/id_ecdsa\n\tIdentityFile ~/.ssh/id_dsa' >> ~/.ssh/config
endif
ifeq ($(UNAME_S),Linux)
	perl -0777 -ne '/# Added by Kryptonite\nHost \*\n\tPKCS11Provider \/usr\/lib\/kr-pkcs11.so\n\tProxyCommand `find \/usr\/bin\/krssh 2>\/dev\/null \|\| which nc` %h %p\n\tIdentityFile ~\/.ssh\/id_kryptonite\n\tIdentityFile ~\/.ssh\/id_ed25519\n\tIdentityFile ~\/.ssh\/id_rsa\n\tIdentityFile ~\/.ssh\/id_ecdsa\n\tIdentityFile ~\/.ssh\/id_dsa/ || exit(1)' ~/.ssh/config || echo '\n# Added by Kryptonite\nHost *\n\tPKCS11Provider /usr/lib/kr-pkcs11.so\n\tProxyCommand `find /usr/bin/krssh 2>/dev/null || which nc` %h %p\n\tIdentityFile ~/.ssh/id_kryptonite\n\tIdentityFile ~/.ssh/id_ed25519\n\tIdentityFile ~/.ssh/id_rsa\n\tIdentityFile ~/.ssh/id_ecdsa\n\tIdentityFile ~/.ssh/id_dsa' >> ~/.ssh/config
endif

start:
ifeq ($(UNAME_S),Linux)
	sudo cp share/kr.service /etc/systemd/user/default.target.wants/kr.service
endif
ifeq ($(UNAME_S),Darwin)
	mkdir -p ~/Library/LaunchAgents
	cp share/co.krypt.krd.plist ~/Library/LaunchAgents/co.krypt.krd.plist
endif
	kr restart

uninstall:
	kr uninstall
