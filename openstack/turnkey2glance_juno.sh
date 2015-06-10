#!/bin/bash
#
#    Copyright (C) 2015 Mohammad Rafiee <m.rafieee@gmail.com>
#			Ramin Shokripour <rshokripour@gmail.com>
#			main code: Loic Dachary <loic@dachary.org>
#
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e

: ${GLANCE:=glance}
: ${DEBIAN_RELEASE:=wheezy}
: ${PUBLIC:=true}

function usage() {
    cat <<EOF
Usage: $0 turnkey-openstack.tar.gz

Upload a http://turnkeylinux.org/ image in the OpenStack image service.

A) download the image and its signature. For instance:

      wget http://downloads.sourceforge.net/project/turnkeylinux/openstack/turnkey-trac-12.0-squeeze-x86-openstack.tar.gz
      wget http://downloads.sourceforge.net/project/turnkeylinux/openstack/turnkey-trac-12.0-squeeze-x86-openstack.tar.gz.sig

B) export the OpenStack credentials in the environment. For instance:

      export OS_PASSWORD=mypassword
      export OS_AUTH_URL=http://os.the.re:5000/v2.0/
      export OS_USERNAME=myuser
      export OS_TENANT_NAME=openstack

C) upload the image. For instance:

      $0 turnkey-trac-12.0-squeeze-x86-openstack.tar.gz

D) check that it shows in glance. For instance:

      glance image-list name=trac-12.0

The homepage for $0 is 
http://redmine.the.re/projects/turnkey/repository/revisions/master/entry/turnkey2glance.sh
EOF
}

function check_credentials() {
    output=$(${GLANCE} image-list 2>&1)
    if [ "$?" != 0 ] ; then
	echo "$output"
	usage
	return 1
    else
	return 0
    fi
}

#
# http://www.turnkeylinux.org/docs/release-verification
#

function check_integrity() {
    local tarbal="$1"

    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 0xA16EB94D || return 1
    gpg --verify "$tarbal.sig" || return 2
}

function tarbal2name() {
    local tarbal="$1"

    [[ $tarbal =~ turnkey-(.*)-${DEBIAN_RELEASE}.* ]] || return 1
    echo ${BASH_REMATCH[1]}
}

function tarbal2dirname() {
    local tarbal="$1"

    basename "$tarbal" -openstack.tar.gz
}

function extract() {
    local tarbal="$1"
    local dirname=$(tarbal2dirname "$tarbal")
    local tar="tar -zxvf $tarbal"

    echo $tar
    $tar || return 1
    if [ ! -d $dirname ] ; then
	echo $tar did not create the expected directory $dirname
	return 2
    fi
}

function name2id() {
    local name="$1"

    ${GLANCE} image-list --name "$name" | tail -2 | awk '{print $2;}' || return 1

}

function rollback() {
    local name="$1"
    local id

    for suffix in -initrd -kernel '' ; do
	id=$(name2id "$name"$suffix) || return 1
	if [ "$id" ] ; then
	    ${GLANCE} --force image-delete "$id" || return 2
	fi
    done
}

function glance_add() {
    local format="$1"
    local name="$2"
    local file="$3"
    local output
    output=$(${GLANCE} image-create --is-public ${PUBLIC} \
	--container-format $format --disk-format $format \
	--name "$name" < "$file" 2>&1)
    if [ $? != 0 ] ; then
	echo "$output"
	return 1
    fi
    name2id "$name"
}

function upload() {
    local tarbal="$1"
    local dirname=$(tarbal2dirname "$tarbal")
    local name=$(tarbal2name "$tarbal")
    local ramdisk_id
    local kernel_id

    extract "$tarbal" || return 1
    ramdisk_id=$(glance_add ari "$name"-initrd "$dirname"/*-initrd) || return 2
    kernel_id=$(glance_add aki "$name"-kernel "$dirname"/*-kernel) || return 3

    ${GLANCE} image-create --is-public ${PUBLIC} \
	--container-format ami --disk-format ami \
	--prop ramdisk_id=$ramdisk_id --prop kernel_id=$kernel_id \
	--name "$name" < $dirname/*.img || return 5
    rm -fr "$dirname"
}

function main() {
	local tarbal="$1"
	local name=$(tarbal2name "$tarbal")
	check_credentials || return 1
#	check_integrity "$tarbal" || return 2
	if upload "$tarbal" ; then
	    ${GLANCE} image-show --name "$name"
	else
	    rollback "$name" || return 3
	    return 4
	fi
}

function run_tests() {
  set -x
  set -o functrace
  PS4=' ${FUNCNAME[0]}: $LINENO: '

  local name=trac-12.0
  local tarbal="turnkey-${name}-squeeze-x86-openstack.tar.gz"

  # cleanup leftover of a previous failed run
  rollback $name || return 1
  rm -f fail
  rm -rf "$(tarbal2dirname $tarbal)"

  if [ "4b241af04bb24df5a049b510c2720903c3cd57df" != "$(sha1sum $tarbal | cut -f1 -d' ')" ] ; then
      wget http://downloads.sourceforge.net/project/turnkeylinux/openstack/$tarbal
      wget http://downloads.sourceforge.net/project/turnkeylinux/openstack/$tarbal.sig
  fi

  ###################### check_credentials
  check_credentials || return 1
  local tenant="$OS_TENANT_NAME"
  unset OS_TENANT_NAME
  ! check_credentials || return 1
  export OS_TENANT_NAME="$tenant"

  ###################### tarbal2name
  ! $(tarbal2name foo) || return 1
  [ $(tarbal2name $tarbal) = $name ] || return 1

  ###################### extract
  extract $tarbal || return 1
  touch fail
  tar -zcvf fail-openstack.tar.gz fail
  ! extract fail-openstack.tar.gz || return 1
  rm fail
  rm -r "$(tarbal2dirname $tarbal)" || return 1

  ###################### glance_add & rollback
  local id
  touch test-initrd
  id=$(glance_add ari "test-initrd" test-initrd)
  [ "$(name2id test-initrd)" = "$id" ] || return 1
  rollback test || return 1
  [ -z "$(name2id test-initrd)" ] || return 1
  rm test-initrd

  touch test-kernel
  id=$(glance_add aki "test-kernel" test-kernel)
  [ "$(name2id test-kernel)" = "$id" ] || return 1
  rollback test || return 1
  [ -z "$(name2id test-kernel)" ] || return 1
  rm test-kernel

  ###################### upload & rollback
  upload $tarbal || return 1
  [ "$(name2id $name-kernel)" ] || return 1
  [ "$(name2id $name-initrd)" ] || return 1
  [ "$(name2id $name)" ] || return 1
  rollback $name
  [ -z "$(name2id $name-kernel)" ] || return 1
  [ -z "$(name2id $name-initrd)" ] || return 1
  [ -z "$(name2id $name)" ] || return 1

  ! upload "WTF.tar.gz" || return 1

  ###################### main
  main $tarbal || return 1
  rollback $name || return 1
}
if [ "$1" = "TEST" ] ; then
    run_tests
elif [ $# != 1 ] || [ "$1" = -h ] || [ "$1" = --help ] ; then
    usage
else
    main "$1"
fi
