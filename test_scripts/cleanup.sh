#! /bin/bash

#
# Cleanup script used by Travis, not the packer build
#
INSTANCE=`cat ec2.instance`
AMI=`cat ec2.ami`
AMI_SNAP=`aws ec2 describe-snapshots --filters Name=owner-id,Values=${AWS_OWNER_ID} Name=description,Values=*${AMI}* | cut -f 6`

if [[ "$INSTANCE" == i-* ]]; then
  echo "Cleaning up Packer created temporary instance: $INSTANCE"
  aws ec2 terminate-instances --instance-ids $INSTANCE
fi

if [[ "$AMI" == ami* ]]; then
  echo "Deregistering Travis AMI image: $AMI"
  aws ec2 deregister-image --image-id $AMI
fi

if [[ "$AMI_SNAP" == snap* ]]; then
  echo "Deleting Travis image snapshot: $AMI_SNAP"
  aws ec2 delete-snapshot --snapshot-id $AMI_SNAP
fi
