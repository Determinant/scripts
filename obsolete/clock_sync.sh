#! /bin/sh
echo "Synchronizing System Clock..."
sudo ntpdate time.nist.gov
sudo hwclock --systohc
echo "Done."
