# Packer templates for Ubuntu

### Overview

This repository contains templates for Ubuntu that can create Vagrant boxes
using Packer.

## Building the boxes

To build all the boxes, you will need VirtualBox, VMware Fusion, and Parallels Desktop for Mac installed, but you can build any combination or one in particular.

Parallels requires that the
[Parallels Virtualization SDK for Mac](http://ww.parallels.com/downloads/desktop)
be installed as an additional preqrequisite.

There's a build script to create the boxes, which can be run with any of the provisioners as an argument, or a comma separated argument list

    ./build.sh vmware-iso,amazon-instance

Note: to build an amazon AMI, ensure your AWS credentials are filled in to vars.json, and 'ec2-ami-tools' is installed via homebrew or otherwise
[Amazon EC2 AMI Tools](http://aws.amazon.com/developertools/368)
You'll also need an x509 certificate, you can create one via script/gen_x509.sh

### Uploading for Vagrant Cloud (in separate sessions for each virtualbox and vmware):
```
brew install awscli
aws configure
s3cmd cp box/xn-ubuntu1404-[virtualbox|vmware]-[version].box s3://xn-boxes/
```

-  Add to https://atlas.hashicorp.com/vagrant under the xnlogic user as xnlogic/xn-ubuntu1404  
-  Create a new version https://atlas.hashicorp.com/xnlogic/boxes/xn-ubuntu1404/versions/new  
-  Add providers: *virtualbox* and *vmware_desktop*
-  Point to s3 url for new box version: http://xn-boxes.s3.amazonaws.com/xn-ubuntu1404-[virtualbox|vmware]-[version].box 
-  Publish  


### Proxy Settings

The templates respect the following network proxy environment variables
and forward them on to the virtual machine environment during the box creation
process, should you be using a proxy:

* http_proxy
* https_proxy
* ftp_proxy
* rsync_proxy
* no_proxy


