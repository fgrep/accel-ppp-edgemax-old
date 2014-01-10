Help wanted!
------------

This is an effort to make accel-ppp work in Ubiquiti EdgeMAX with all options configurable via vyatta cli.

Overview
--------

- Patches to build and configure accel-ppp for Ubiquiti EdgeMAX (http://www.ubnt.com/edgemax)
- Debian rules and patches based on Aleksey Zhukov work (https://github.com/drdaeman)
- accel-ppp Copyright: Dmitry Kozlov <xeb@mail.ru>  (http://sourceforge.net/projects/accel-ppp)

Setting up toolchain and building with dpkg-buildpackage
--------------------------------------------------------
Clean and basic Debian squeeze (used 6.0.8 amd64, and only selected SSH Server during install package selection)

```
aptitude install emdebian-archive-keyring

echo 'deb http://www.emdebian.org/debian/ squeeze main' >> /etc/apt/sources.list
echo 'deb http://debian.c3sl.ufpr.br/debian-backports squeeze-backports main' >> /etc/apt/sources.list

aptitude update
aptitude install gcc-4.4-mips-linux-gnu cmake git debhelper xapt
xapt -a mips libc6-dev libpcre3-dev libssl-dev zlib1g-dev libnl2-dev debhelper linux-headers-octeon
ln -s /usr/mips-linux-gnu/src/linux-headers-3.2.0-0.bpo.4-common/arch/mips/include/asm/octeon /usr/mips-linux-gnu/include/asm/octeon
su - myuser
mkdir buildenv; cd buildenv
git clone git://git.code.sf.net/p/accel-ppp/code accel-ppp-1.8.0-beta
git clone https://github.com/fgrep/accel-ppp-edgemax.git accel-ppp-edgemax
tar -zcf accel-ppp_1.8.0-beta.orig.tar.gz accel-ppp-1.8.0-beta
cp -a accel-ppp-edgemax/debian accel-ppp-1.8.0-beta/
cd accel-ppp-1.8.0-beta
fakeroot dpkg-buildpackage -amips
```

Done.
