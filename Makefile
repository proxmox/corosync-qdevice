include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=corosync-qdevice

CSVERSION=${DEB_VERSION_UPSTREAM}

BUILDDIR=${PACKAGE}-${CSVERSION}
CSSRC=src

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell git rev-parse HEAD)

MAIN_DEB=corosync-qdevice_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \

OTHER_DEBS=\
corosync-qnetd_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb

DBG_DEBS=\
corosync-qdevice_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
corosync-qnet-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb

DEBS=${MAIN_DEB} ${OTHER_DEBS} ${DBG_DEBS}

DSC=${PACKAGE}_${DEB_VERSION}.dsc

all: ${DEBS}
	echo ${DEBS}

${BUILDDIR}: submodule debian/changelog
	rm -rf $@ $@.tmp
	cp -a ${CSSRC} $@.tmp
	cp -a debian $@.tmp
	mv $@.tmp $@

.PHONY: deb
deb: ${DEBS}
${OTHER_DEBS} ${DBG_DEBS}: ${MAIN_DEB}
${MAIN_DEB}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -b -us -uc
	lintian ${MAIN_DEB} ${OTHER_DEBS}

.PHONY: dsc
dsc: ${DSC}
${DSC}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -S -us -uc -d -nc

.PHONY: submodule
submodule:
	test -f "${CSSRC}/Makefile.am" || git submodule update --init ${CSSRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh -X repoman@repo.proxmox.com -- upload --product pve --dist buster --arch ${DEB_BUILD_ARCH}

.PHONY: clean
distclean: clean
clean:
	rm -rf *.deb *.changes *.dsc *.buildinfo ${BUILDDIR} ${PACKAGE}-*/
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
