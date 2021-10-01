!#/bin/bash
export RAWDISK=/dev/sdh
if test -L "$RAWDISK"1; 
then
  echo Skipping as disk already formatted
else
  (echo o; echo n;echo p;echo 1;echo ; echo ;echo w;) | sudo fdisk $RAWDISK
  sleep 5 
  export DISK="$RAWDISK"1
  sudo mkfs -t ext4 $DISK 
  DISK_UUID=$(sudo blkid -s UUID -o value blkid $DISK)
  sudo mkdir -p /mnt/disks/$DISK_UUID
  sudo mount -t ext4 $DISK /mnt/disks/$DISK_UUID
  echo UUID=`sudo blkid -s UUID -o value $DISK` /mnt/disks/$DISK_UUID ext4 defaults 0 0 | sudo tee -a /etc/fstab
fi
