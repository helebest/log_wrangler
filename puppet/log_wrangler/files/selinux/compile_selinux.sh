#!/bin/bash

CHKMOD=/usr/bin/checkmodule
MODPKG=/usr/bin/semodule_package
SEMOD=/usr/sbin/semodule

selinux_mod_file=${1/te/mod};
${CHKMOD} -M -m -o ${selinux_mod_file} ${1};
selinux_pp_file=${1/te/pp};
${MODPKG} -o ${selinux_pp_file} -m ${selinux_mod_file};
