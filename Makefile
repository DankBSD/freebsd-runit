CMARK?=		cmark
FIND?=		find
GIT?=		git
HUB?=		hub
IGOR?=		igor
INSTALL_MAN?=	install -m 444
INSTALL_PROGRAM?=	install -s -m 555
INSTALL_SCRIPT?=	install -m 555
LN?=		ln
MANDOC?=	mandoc
MKDIR?=		mkdir -p
PRINTF?=	printf
SED?=		sed
SHELLCHECK?=	shellcheck
SHFMT?=		shfmt
TAR?=		tar
XARGS?=		xargs
XZ_CMD?=	xz -Mmax

LOCALBASE?=	/usr/local
PREFIX?=	/usr/local
DOCSDIR?=	${PREFIX}/share/doc/runit
RUNITDIR?=	${PREFIX}/etc/runit
SBINDIR?=	${PREFIX}/sbin
SVDIR?=		${PREFIX}/etc/sv

GETTYSV=	ttyv0 ttyv2 ttyv3 ttyv4 ttyv5 ttyv6 ttyv7 ttyv8
GETTYSU=	ttyu0 ttyu1 ttyu2 ttyu3

all:
	echo '#define RUNITDIR "${RUNITDIR}"' > runit/src/runit.local.h
	echo '#define SBINDIR "${SBINDIR}"' >> runit/src/runit.local.h
	echo "${CC} ${CFLAGS}" > runit/src/conf-cc
	echo "${CC}" > runit/src/conf-ld
	cd runit && ./package/compile

install:
	@${MKDIR} ${DESTDIR}${PREFIX}/bin ${DESTDIR}${PREFIX}/sbin ${DESTDIR}${SBINDIR} \
		${DESTDIR}${RUNITDIR} ${DESTDIR}${DOCSDIR}
	cd runit/command && \
		${INSTALL_PROGRAM} runit runit-init ${DESTDIR}${SBINDIR}
	cd runit/command && \
		${INSTALL_PROGRAM} chpst runsv runsvchdir runsvdir sv svlogd \
		utmpset ${DESTDIR}${PREFIX}/sbin
	@${MKDIR} ${DESTDIR}${PREFIX}/man/man8
	${INSTALL_MAN} runit/man/*.8 ${DESTDIR}${PREFIX}/man/man8
	@${SED} -i '' -e 's,/usr/local/etc/runit,${RUNITDIR},g' \
		${DESTDIR}${PREFIX}/man/man8/*.8
	@${TAR} -C etc/runit --exclude .gitkeep -cf - . | ${TAR} -C ${DESTDIR}${RUNITDIR} -xf -
	@${FIND} ${DESTDIR}${RUNITDIR} -type f -exec ${SED} -i '' \
		-e 's,/usr/local/etc/runit,${RUNITDIR},g' \
		-e 's,//etc,/etc,' \
		-e 's,/usr/local,${LOCALBASE},g' {} \;

format:
	${SHFMT} -w -s -p bin etc/runit etc/sv

manlint:
	${MANDOC} -Tlint docs/runit-faster.7 docs/svclone.8 docs/svmod.8
	${IGOR} docs/runit-faster.7 docs/svclone.8 docs/svmod.8

lint:
	${SHFMT} -d -s -p bin etc/runit etc/sv
	${SHFMT} -p -f bin etc/runit etc/sv | ${XARGS} ${SHELLCHECK} -s sh -x -e SC1091,SC2039

check:
	cd runit && package/check

archive:
	@tag=$$(${GIT} tag --contains HEAD); ver=$${tag#v*}; \
		${GIT} archive --format=tar \
			--prefix=freebsd-runit-$$ver/ \
			--output=freebsd-runit-$$ver.tar \
			$$tag && \
		${XZ_CMD} -f freebsd-runit-$$ver.tar

github-release: archive
	@${GIT} push --follow-tags github
	@tag=$$(${GIT} tag --contains HEAD); ver=$${tag#v*}; \
		${HUB} release create -p -a freebsd-runit-$$ver.tar.xz \
			-m "freebsd-runit-$$ver" $$tag

docs: docs/runit-faster.html docs/runit-faster.7.html

docs/runit-faster.html: docs/runit-faster.md
	${CMARK} docs/runit-faster.md > docs/runit-faster.html

docs/runit-faster.7.html: docs/runit-faster.7
	${MANDOC} -Thtml docs/runit-faster.7 | ${SED} \
	's,</style>,&<link rel="stylesheet" type="text/css" href="buttondown.css">,' \
	> docs/runit-faster.7.html

.PHONY: all archive check docs format github-release manlint lint
