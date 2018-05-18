#! /bin/bash

#
# promgen.sh
#
# Convert Vivado's *.bit bitstream output file into
# the *.bit.bin format required for sending to the
# PetaLinux /dev/xdevcfg device for FPGA configuration.
#
# On the MicroZed (from the Linux shell prompt), load FPGA with (e.g.)
#   cat design_1_wrapper.bit.bin >> /dev/xdevcfg
#
# 2014-12-15 wja
#
if [ -f /opt/Xilinx/14.3/LabTools/settings64.sh ] 
then
  echo found LabTools
  . /opt/Xilinx/14.3/LabTools/settings64.sh
else
  echo Did not find LabTools
  . $(ls -1d /opt/Xilinx/14.[67]/ISE_DS/settings64.sh | tail -1)
fi
export LM_LICENSE_FILE=1700@head.hep.upenn.edu
dir=proj/proj.runs/impl_1
bit=bd_wrapper
projname=mrb_uzed
ofnam=${projname}.bin
echo "== reading $dir/${bit}.bit / writing $ofnam =="
promgen -b -w -p bin -data_width 32 -u 0 \
  ${dir}/${bit}.bit -o $ofnam
/bin/rm -f ${projname}.prm
/bin/rm -f ${projname}.cfi
ls -lh $ofnam
echo $(pwd)/$ofnam
cksum $ofnam | tee ${ofnam}.cksum
echo /bin/cp -p $ofnam /export/uzed/
/bin/cp -p $ofnam /export/uzed/
ls -lh /export/uzed/$ofnam
cksum /export/uzed/$ofnam
