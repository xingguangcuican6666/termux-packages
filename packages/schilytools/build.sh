TERMUX_PKG_HOMEPAGE=https://codeberg.org/schilytools/schilytools
TERMUX_PKG_DESCRIPTION="A collection of tools written or formerly managed by Jörg Schilling"
TERMUX_PKG_LICENSE="BSD, BSD 2-Clause, BSD 3-Clause, CDDL-1.0, GPL-2.0-or-later, LGPL-2.1-or-later, MIT"
TERMUX_PKG_LICENSE_FILE="
patch/LICENSE
libfile/LEGAL.NOTICE
CDDL.Schily.txt
GPL-2.0.txt
LGPL-2.1.txt
"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="2024-03-21"
# upstream requests in release notes to use this mirror to obtain release tarball
TERMUX_PKG_SRCURL="https://schilytools.pkgsrc.pub/pub/schilytools/schily-$TERMUX_PKG_VERSION.tar.bz2"
TERMUX_PKG_SHA256=76db022e450c1791a00e69780b55d18a2e3fc39b5ff870996433f87312032024
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	# Cross-compile: pre-set autoconf cache to avoid running test programs
	# (safeguard common runtime checks for Android aarch64/arm/i386/x86_64)
	export ac_cv_func_vfork=yes
	export ac_cv_func_vfork_works=yes
	export ac_cv_func_getgrent=yes
	export ac_cv_func_setgrent=yes
	export ac_cv_func_endgrent=yes
	export ac_cv_func_getloadavg=yes
	export ac_cv_func_valloc=no
	export ac_cv_func_setreuid=no
	export ac_cv_func_setresuid=no
	export ac_cv_func_seteuid=no
	export ac_cv_func_setuid=no
	export ac_cv_func_setregid=no
	export ac_cv_func_setresgid=no
	export ac_cv_func_setegid=no
	export ac_cv_func_setgid=no
	export ac_cv_func_setpgid=no
	export ac_cv_dev_minor_bits=20
	export ac_cv_dev_minor_noncontig=no
	export ac_cv_header_containing_minor=sys/sysmacros.h
	export ac_cv_header_containing_major=sys/sysmacros.h
	export ac_cv_header_containing_mkedev=sys/sysmacros.h
	export ac_cv_wnowait_waitpid=yes
	export ac_cv_c_const=yes
	export ac_cv_c_bitfields_htol=no

	# common sizeof/struct assumptions
	export ac_cv_type_prototypes=yes
	export ac_cv_sizeof_char=1
	export ac_cv_sizeof_short_int=2
	export ac_cv_sizeof_int=4
	export ac_cv_sizeof_long_long=8
	export ac_cv_sizeof_long_double=16
	export ac_cv_sizeof_wchar_t=4
	export ac_cv_sizeof_double=8
	export ac_cv_sizeof_float=4

	# disable runtime tests that require executing compiled programs
	export ac_cv_func_mmap=no
	export ac_cv_func_shmget=no
	export ac_cv_func_mlock=no
	export ac_cv_func_mlockall=no

	# Arch-specific pointer/long/size_t widths
	case "$TERMUX_ARCH" in
	  aarch64|x86_64)
	    export ac_cv_sizeof_long_int=8
	    export ac_cv_sizeof_size_t=8
	    export ac_cv_sizeof_ptrdiff_t=8
	    export ac_cv_sizeof_char_p=8
	    ;;
	  arm|i686|x86)
	    export ac_cv_sizeof_long_int=4
	    export ac_cv_sizeof_size_t=4
	    export ac_cv_sizeof_ptrdiff_t=4
	    export ac_cv_sizeof_char_p=4
	    ;;
	esac

	# if [[ "$TERMUX_ON_DEVICE_BUILD" == "false" ]]; then
	# 	termux_error_exit "This package is extremely hard to cross-compile. If you know how, please help!"
	# fi

	mv rmt/{,s}rmt.dfl
	mv rmt/default-{,s}rmt.sample

	# make sure most of the programs go to $TERMUX_PREFIX/bin
	sed -i "s|/opt/schily|$TERMUX_PREFIX|g" DEFAULTS/Defaults.linux
	sed -i 's|INSDIR=\s*sbin|INSDIR=bin|' rscsi/Makefile

	find "$TERMUX_PKG_SRCDIR" -type f | xargs -n 1 sed -i \
		-e "s|/etc|$TERMUX_PREFIX/etc|g" \
		-e "s|/tmp|$TERMUX_PREFIX/tmp|g"

	LDFLAGS+=" -landroid-shmem"
	
}

termux_step_configure() {
	if [[ "$TERMUX_PKG_API_LEVEL" -lt 26 ]]; then
		export ac_cv_func_sigset=no
		export ac_cv_func_getdomainname=no
	else
		export ac_cv_func_sigset=yes
		export ac_cv_func_getdomainname=yes
	fi

	# normal Android 7 does not have getgrent,
	# but it is implemented as a stub in Termux
	# in ndk-patches/28c/grp.h.patch
	export ac_cv_func_getgrent=yes
	export ac_cv_func_setgrent=yes
	export ac_cv_func_endgrent=yes

	# polyfilled using android-no-getloadavg.patch
	export ac_cv_func_getloadavg=yes

	# All android have valloc implemented in libc.so,
	# but it is disabled in headers for Android 5 and newer
	export ac_cv_func_valloc=no

	# Fix 'Bad system call'
	export ac_cv_func_setreuid=no
	export ac_cv_func_setresuid=no
	export ac_cv_func_seteuid=no
	export ac_cv_func_setuid=no
	export ac_cv_func_setregid=no
	export ac_cv_func_setresgid=no
	export ac_cv_func_setegid=no
	export ac_cv_func_setgid=no
	export ac_cv_func_setpgid=no
	export ac_cv_dev_minor_bits=20
	export ac_cv_dev_minor_noncontig=no
	export ac_cv_header_containing_minor=sys/sysmacros.h
	export ac_cv_header_containing_major=sys/sysmacros.h
	export ac_cv_header_containing_mkedev=sys/sysmacros.h
	export ac_cv_wnowait_waitpid=yes
	export ac_cv_c_const=yes
	export ac_cv_c_bitfields_htol=no

	# Fix sizeof tests
	export ac_cv_type_prototypes=yes
	# export ac_cv_type_timestruc_t=yes
	export ac_cv_sizeof_char=1
	export ac_cv_sizeof_short_int=2
	export ac_cv_sizeof_int=4
	export ac_cv_sizeof_long_int=8
	export ac_cv_sizeof_long_long=8
	# export ac_cv_sizeof_=8
	export ac_cv_sizeof_size_t=8
	export ac_cv_sizeof_time_t=8
	export ac_cv_sizeof___int64=8
	export ac_cv_sizeof_wchar_t=4
	export ac_cv_sizeof_wchar=4
	export ac_cv_sizeof_dev_t=8
	export ac_cv_sizeof_gid_t=4
	export ac_cv_sizeof_uid_t=4
	export ac_cv_sizeof_double=8
	export ac_cv_sizeof_major_t=4
	export ac_cv_sizeof_mode_t=4
	export ac_cv_sizeof_minor_t=4
	export ac_cv_sizeof_pid_t=4
	export ac_cv_sizeof_ptrdiff_t=8
	export ac_cv_sizeof_ssize_t=8
	export ac_cv_sizeof_unsigned_short_int=2
	export ac_cv_sizeof_unsigned___int64=8
	export ac_cv_sizeof_unsigned_char=1
	export ac_cv_sizeof_unsigned_char_p=8
	export ac_cv_sizeof_unsigned_int=4
	export ac_cv_sizeof_unsigned_long_int=8
	export ac_cv_sizeof_unsigned_long_long=8
	export ac_cv_sizeof_unsigned_short_int=2
	export ac_cv_sizeof_char_p=8
	export ac_cv_sizeof_float=4
	export ac_cv_sizeof_long_double=16
	export ac_cv_func_mlock=no
	export ac_cv_func_mlockall=no
	export ac_cv_func_ecvt=no
	export ac_cv_func_fcvt=no
	export ac_cv_func_gcvt=no
	export ac_cv_func_quotaioctl=no
	export ac_cv_func_dtoa_r=no
	
}

termux_step_make() {
	make \
		INS_BASE="$TERMUX_PREFIX" \
		INS_RBASE="$TERMUX_PREFIX" \
		VERSION_OS="_Termux" \
		CCOM=clang \
		CC="$CC" \
		CCC="$CXX" \
		COPTX="$CFLAGS" \
		C++OPTX="$CXXFLAGS" \
		LDOPTX="$LDFLAGS" \
		MINOR_BITS=20
}

termux_step_make_install() {
	make \
		INS_BASE="$TERMUX_PREFIX" \
		INS_RBASE="$TERMUX_PREFIX" \
		install
}

termux_step_post_make_install() {
	# move some stuff out of direct subfolders of $TERMUX_PREFIX
	rm -rf "$TERMUX_PREFIX/opt/schily"
	mkdir -p "$TERMUX_PREFIX/opt/schily"
	mv "$TERMUX_PREFIX/ccs" "$TERMUX_PREFIX/opt/schily/"
	mv "$TERMUX_PREFIX/xpg4" "$TERMUX_PREFIX/opt/schily/"
	ln -sf "$TERMUX_PREFIX/opt/schily/ccs/bin/sccs" "$TERMUX_PREFIX/bin/sccs"
	ln -sf rmchg "$TERMUX_PREFIX/opt/schily/ccs/bin/cdc"
	ln -sf rmchg "$TERMUX_PREFIX/opt/schily/ccs/bin/rmdel"
	ln -sf unget "$TERMUX_PREFIX/opt/schily/ccs/bin/sact"
	ln -sf "$TERMUX_PREFIX/bin/spatch" "$TERMUX_PREFIX/opt/schily/ccs/bin/sccspatch"

	# Create symlinks for cdrkit compatibility
	ln -sf cdrecord "$TERMUX_PREFIX/bin/wodim"
	ln -sf readcd "$TERMUX_PREFIX/bin/readom"
	ln -sf mkisofs "$TERMUX_PREFIX/bin/genisoimage"
	ln -sf cdda2wav "$TERMUX_PREFIX/bin/icedax"
}
