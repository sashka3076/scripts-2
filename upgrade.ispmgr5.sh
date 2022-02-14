#!/bin/sh
# Upgrade for ISPmanager 5 to ISPmanager 6
#set -e

centos_OSVERSIONS="7 8"
debian_OSVERSIONS="stretch buster"
ubuntu_OSVERSIONS="xenial bionic focal"
release="stable5"
FAILSAFEMIRROR=mirrors.download.ispsystem.com
SCHEMA=https

Infon() {
	# shellcheck disable=SC2059,SC2145
	printf "\033[1;32m$@\033[0m"
}

Info()
{
	# shellcheck disable=SC2059,SC2145
	Infon "$@\n"
}

Warningn() {
	# shellcheck disable=SC2059,SC2145
	printf "\033[1;35m$@\033[0m"
}

Warning()
{
	# shellcheck disable=SC2059,SC2145
	Warningn "$@\n"
}

Warnn()
{
	# shellcheck disable=SC2059,SC2145
	Warningn "$@"
}

Warn()
{
	# shellcheck disable=SC2059,SC2145
	Warnn "$@\n"
}

Error()
{
	# shellcheck disable=SC2059,SC2145
	printf "\033[1;31m$@\033[0m\n"
}

OSDetect() {
	test -n "${ISPOSTYPE}" && return 0
	ISPOSTYPE=unknown
	kern=$(uname -s)
	case "${kern}" in
		Linux)
		if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
			# RH family
			export ISPOSTYPE=REDHAT
		elif [ -f /etc/debian_version ]; then
			# DEB family
			export ISPOSTYPE=DEBIAN
		fi
		;;
		FreeBSD)
			# FreeBSD
			export ISPOSTYPE=FREEBSD
		;;
	esac
	if [ "#${ISPOSTYPE}" = "#unknown" ]; then
		Error "Unknown os type. Try to use \"--osfamily\" option"
		exit 1
	fi
}

OSVersion() {
	test -n "${OSVER}" && return 0
	OSVER=unknown
	case ${ISPOSTYPE} in
		REDHAT)
			# Updating CA certs
			yum -y update ca-certificates
			/usr/bin/ca-legacy install
			/usr/bin/update-ca-trust
			if ! which which >/dev/null 2>/dev/null ; then
				yum -y install which
			fi
			if [ -z "$(which hexdump 2>/dev/null)" ]; then
				yum -y install util-linux-ng
			fi
			OSVER=$(rpm -q --qf "%{version}" -f /etc/redhat-release)
			if echo "${OSVER}" | grep -q Server ; then
				OSVER=$(echo "${OSVER}" | sed 's/Server//')
			fi
			OSVER=${OSVER%%\.*}
			if ! echo "${centos_OSVERSIONS}" | grep -q -w "${OSVER}" ; then
				unsupported_osver="true"
			fi
		;;
		DEBIAN)
			/usr/bin/apt-get -qy update
			# Updating CA certs
			apt-get -qy --allow-unauthenticated -u install ca-certificates
			if ! which which >/dev/null 2>/dev/null ; then
				/usr/bin/apt-get -qy --allow-unauthenticated install which
			fi
			local toinstall
			if [ -z "$(which lsb_release 2>/dev/null)" ]; then
				toinstall="${toinstall} lsb-release"
			fi
			if [ -z "$(which hexdump 2>/dev/null)" ]; then
				toinstall="${toinstall} bsdmainutils"
			fi
			if [ -z "$(which logger 2>/dev/null)" ]; then
				toinstall="${toinstall} bsdutils"
			fi
			if [ -z "$(which free 2>/dev/null)" ]; then
				toinstall="${toinstall} procps"
			fi
			if [ -z "$(which python 2>/dev/null)" ]; then
				toinstall="${toinstall} python"
			fi
			if [ -z "$(which gpg 2>/dev/null)" ]; then
				toinstall="${toinstall} gnupg"
			fi
			if [ -z "$(which wget curl 2>/dev/null)" ]; then
				toinstall="${toinstall} wget"
			fi
			if [ -n "${toinstall}" ]; then
				/usr/bin/apt-get -qy --allow-unauthenticated install ${toinstall}
			fi
			if [ -x /usr/bin/lsb_release ]; then
				OSVER=$(lsb_release -s -c)
			fi
			if ! echo "${debian_OSVERSIONS} ${ubuntu_OSVERSIONS}" | grep -q -w "${OSVER}" ; then
				unsupported_osver="true"
			fi
			if [ "$(lsb_release -s -i)" = "Ubuntu" ]; then
				export reponame=ubuntu
			else
				export reponame=debian
			fi
		;;
	esac
	if [ "#${OSVER}" = "#unknown" ]; then
		Error "Unknown os version. Try to use \"--osversion\" option"
		exit 1
	fi
	if [ "#${unsupported_osver}" = "#true" ]; then
		Error "Unsupported os version (${OSVER})"
		exit 1
	fi
}

DetectFetch()
{
	if [ -x /usr/bin/fetch ]; then
		fetch="/usr/bin/fetch -o "
	elif [ -x /usr/bin/wget ]; then
		# shellcheck disable=SC2154
		if [ "$unattended" = "true" ]; then
			fetch="/usr/bin/wget -T 30 -t 10 --waitretry=5 -q -O "
		else
			fetch="/usr/bin/wget -T 30 -t 10 --waitretry=5 -q -O "
		fi
	elif [ -x /usr/bin/curl ]; then
		fetch="/usr/bin/curl --connect-timeout 30 --retry 10 --retry-delay 5 -o "
	else
		Error "ERROR: no fetch program found."
		exit 1
	fi
}

CheckMirror() {
	# $1 - mirror
	${fetch} - http://${1}/ | grep -q install.sh
}

GetFastestMirror() {
	# Detect fastest mirror. If redhat not needed. If mirror detected not needed

	case ${ISPOSTYPE} in
		REDHAT)
			export BASEMIRROR=mirrors.download.ispsystem.com
		;;
		DEBIAN)
			if CheckMirror download.ispsystem.com ; then
				export BASEMIRROR=download.ispsystem.com
			else
				export BASEMIRROR=mirrors.download.ispsystem.com
			fi
		;;
	esac

	case ${ISPOSTYPE} in
		REDHAT)
			export MIRROR=mirrors.download.ispsystem.com
		;;
		DEBIAN)
			if CheckMirror download.ispsystem.com ; then
				export MIRROR=download.ispsystem.com
			else
				export MIRROR=${FAILSAFEMIRROR}
			fi
		;;
	esac
	Info " Using ${MIRROR}"
}

CheckRepo() {
  if grep "beta" /usr/local/mgr5/etc/repo.version; then
    release="beta5"
  fi
}

GetAvailVersion() {
	local rel
	rel=$1
	test -n "${rel}" || return 1

	case ${ISPOSTYPE} in
		REDHAT)
			LC_ALL=C yum list -q --showduplicates coremanager 2>/dev/null | awk -v rel=${rel} 'BEGIN{flag=0} {if($1 ~ /Available/){flag=1; getline};{if(flag==1 && $3 == "ispsystem-"rel){print $2}}}' | sort -V | tail -1
			;;
		DEBIAN)
			apt-get -y update >/dev/null 2>&1
			apt-cache madison coremanager 2>/dev/null| awk -v rel=${rel} -v dist=$(lsb_release -c -s) '$6 == rel"-"dist"/main" {print $3}' | sort -V | tail -1
			;;
		esac
}

GetInstalledVersion() {
	case ${ISPOSTYPE} in
		REDHAT)
			rpm -q --qf "%{version}-%{release}" coremanager 2>/dev/null
			;;
		DEBIAN)
			dpkg -s coremanager 2>/dev/null | grep Version | awk '{print $2}'
			;;
		esac
}

VersionToRelease() {
	# $1 - version
	echo "${1}" | awk -F- '{print $1}' | cut -d. -f1,2
}

PkgRemove() {
	# Remove package
	case ${ISPOSTYPE} in
		REDHAT)
			# shellcheck disable=SC2068
			yum -y remove ${@}
		;;
		DEBIAN)
			# shellcheck disable=SC2068
			apt-get -y -q remove ${@}
		;;
		*)
			return 1
		;;
	esac
}

PkgInstall() {
	# Install package if error change mirror if possible
	# shellcheck disable=SC2039
	local pi_fail
	pi_fail=1
	while [ "#${pi_fail}" = "#1" ]; do
		pi_fail=0
		case ${ISPOSTYPE} in
			REDHAT)
				# shellcheck disable=SC2068
				yum -y install ${@} || pi_fail=1
			;;
			DEBIAN)
				apt-get -y update
				# shellcheck disable=SC2068
				apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -q install ${@} || pi_fail=1
			;;
			*)
			;;
		esac
		if [ "#${pi_fail}" = "#0" ]; then
			return 0
			break
		else
			return 1
			break
		fi
	done
}

CheckDowngrade() {
	chk_inst_ver=$(VersionToRelease $(GetInstalledVersion))
	chk_avail_ver=$(VersionToRelease $(GetAvailVersion ${release}))
	Info "Installed version: ${chk_inst_ver}"
	Info "Remote version in repo ${release}: ${chk_avail_ver}"

	if [ "$(printf '%s\n' "$chk_inst_ver" "$chk_avail_ver" | sort -V | head -n1)" = "$chk_avail_ver" ]; then
		release=${chk_inst_ver}
		InstallRepo
	fi
}

CentosRepo() {
    local release rname
    release="${1}"
    rname="${2}"

    rm -f /etc/yum.repos.d/${rname}.repo
    if echo "${release}" | grep -qE "^(6-)?(stable|beta|beta5|stable5|intbeta|intstable|5\.[0-9]+)$"; then
        ${fetch} /etc/yum.repos.d/${rname}.repo.tmp "${SCHEMA}://${MIRROR}/repo/centos/ispsystem5.repo" >/dev/null 2>&1 || return 1
        sed -i -r "s/__VERSION__/${release}/g" /etc/yum.repos.d/${rname}.repo.tmp && mv /etc/yum.repos.d/${rname}.repo.tmp /etc/yum.repos.d/${rname}.repo || exit
    else
        ${fetch} /tmp/${rname}.repo "${SCHEMA}://${MIRROR}/repo/centos/ispsystem-template.repo" >/dev/null 2>&1 || return 1
        sed -i -r "s|TYPE|${release}|g" /tmp/${rname}.repo
        mv /tmp/${rname}.repo /etc/yum.repos.d/${rname}.repo
    fi
}


DebianRepo() {
	local release rname
	release="${1}"
	rname="${2}"

	rm -f /etc/apt/sources.list.d/${rname}.list
    if echo "${release}" | grep -qE "^(6-)?(stable|beta|intbeta|intstable|5\.[0-9]+)$"; then
		if echo "${release}" | grep -qE "5\.[0-9]+"; then
			echo "deb http://${MIRROR}/repo/${reponame} ${release}-${OSVER} main" > /etc/apt/sources.list.d/${rname}.list
		else
			echo "deb ${SCHEMA}://${MIRROR}/repo/${reponame} ${release}-${OSVER} main" > /etc/apt/sources.list.d/${rname}.list
		fi
	else
		echo "deb http://${MIRROR}/repo/${reponame} ${release}-${OSVER} main" > /etc/apt/sources.list.d/${rname}.list
	fi

}

InstallRepo() {
  Info "Use ${release} release"
	case ${ISPOSTYPE} in
			REDHAT)
		Info "Adding repository ISPsystem.."
		CentosRepo "${release}" "ispsystem"
		Info "Adding repository ISPsystem-6.."
		CentosRepo "6-${release}" "exosoft"
		;;
			DEBIAN)
		Info "Adding repository ISPsystem.."
		DebianRepo "${release}" "ispsystem"
		Info "Adding repository ISPsystem-6.."
		DebianRepo "6-${release}" "exosoft"
		;;
	esac
}

UpTo6() {
	Info "Update ISPmanager.."
	/usr/local/mgr5/sbin/pkgupgrade.sh coremanager
}

OSDetect
OSVersion

Infon "${ISPOSTYPE}-${OSVER}"

DetectFetch
GetFastestMirror
CheckRepo
InstallRepo
CheckDowngrade
UpTo6
