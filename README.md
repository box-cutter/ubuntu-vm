# Packer templates for Ubuntu

Checkout and increment version number in xn-ubuntu1404.json then:
```
packer build xn-ubuntu1404.json
```

Upload (in separate sessions for each virtualbox and vmware):
```
brew install awscli
aws configure
s3cmd cp box/[virtualbox|vmware]/xn-ubuntu1404-nocm-[version].box s3://xn-boxes/[virtualbox|vmware]/
```

-  Add to https://atlas.hashicorp.com/vagrant under the xnlogic user as xnlogic/xn-ubuntu1404  
-  Create a new version https://atlas.hashicorp.com/xnlogic/boxes/xn-ubuntu1404/versions/new  
-  Add providers: *virtualbox* and *vmware_desktop*
-  Point to s3 url for new box version: http://xn-boxes.s3.amazonaws.com/[virtualbox|vmware]/xn-ubuntu1404-nocm-[version].box  

