## OS Images

These [Packer](http://www.packer.io/) templates create Ubuntu and CentOS Linux OVA images primarily via the [VirtualBox](https://www.virtualbox.org/) [builder](https://www.packer.io/docs/builders/). However, the templates are straightforward enough to be used as a based for other work:

|Template Name|OS|Packer Builder|Status|
|---|---|---|---|
|ubuntu2004.json|Ubuntu 20.04|VirtualBox|Working|
|ubuntu1804.json|Ubuntu 18.04|VirtualBox|Working|
|centos81911.json|CentOS 8.1.1911|VirtualBox|Working|
|centos72003.json|CentOS 7.8.2003|VirtualBox|Working|
|centos71911.json|CentOS 7.7.1911|VirtualBox|Working|
|centos71908.json|CentOS 7.7.1908|VirtualBox|Working|
|centos71908pvm.json|CentOS 7.7.1908|Parallels|Untested|
|centos71908ami.json|CentOS 7.7.1908|AWS|Untested|

## Prerequisites
These templates have been tested on macOS v10.15.4, and some on Windows 10. You need at least the following versions of these applications:
  * VirtualBox v6.1.6
  * Packer v1.5.6

## Getting Started
Validate a specific template, then build the image. For example:
```
packer validate ubuntu1804.json
packer build ubuntu1804.json
```
Test the new OVA image with something like the `vm` utility ([hosted here](https://github.com/lencap/vm)) to test the OVA image:
```
vm create dev1 output-virtualbox-iso/ubuntu1804.ova
vm start dev1
vm ssh dev1
vm imgimp output-virtualbox-iso/ubuntu1804.ova
```

## Vagrant
[Vagrant](https://www.vagrantup.com/intro/index.html) is another open-source software product for building and maintaining portable virtual software development environments. To use these OS images with Vagrant you can either:

1. Run `vagrant package [etc]` against a VM created from one of these default OVA images, or

2. Create a new template based on one of these templates, by adding a post-processors stanza, like this:
```
  "post-processors": [
    {
      "type": "vagrant",
      "keep_input_artifact": true,
      "output": "./centos72003.box",
      "vagrantfile_template": "./Vagrantfile"
    }
  ]
```
A Vagrantfile is included as example, but you'll need to read more of the Vagrant documentation for further use.

Of course, once you have a working Vagrantfile, you can test with commands such as:
```
vagrant up
vagrant ssh
vagrant destroy
vagrant box remove ubuntu1804
```

## Parallels
Also included is a [Packer](http://www.packer.io/) template to create a [Parallels](https://www.parallels.com/) [PVM](https://en.wikipedia.org/wiki/Parallel_Virtual_Machine) OS image. Note that this is a still a work in progress.

To play with this further, make sure you install __Parallels v14.1.0__ or above, and the Parallels Virtualization SDK, as well as the Vagrant provider (if using Vagrant):
```
brew cask install parallels-virtualization-sdk
vagrant plugin install vagrant-parallels
```
To build the images:
```
packer validate centos71908pvm.json   # Confirm template is good
packer build centos71908pvm.json      # Build CentOS 7 1908 Parallels PVM machine
```

## Amazon
Also a [Packer](http://www.packer.io/) template to create an Amazon [AMIs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html).

Tested from macOS v10.14.2, but should work on any Linux OS.

* On target AWS account, create a `packer` IAM user, and attach below `PackerBuilder` policy.
  ```
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PackerBuilder",
        "Effect": "Allow",
        "Action": [
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CopyImage",
          "ec2:CopyImage",
          "ec2:CreateImage",
          "ec2:CreateKeypair",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteKeypair",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume",
          "ec2:DeregisterImage",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume",
          "ec2:GetPasswordData",
          "ec2:ModifyImageAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifySnapshotAttribute",
          "ec2:RegisterImage",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ],
        "Resource": "*"
      }
    ]
  }
  ```

* Logon to target AWS account via CLI using above `packer` user.
* Ensure `aws_source_ami` is the CentOS 7 image base you need.
* Ensure `aws_security_group_ids` are valid EC2 Security Group IDs in your target AWS account 
* STILL UNDER CONSTRUCTION ... there are more parameters

Build image by doing the usual:
```
packer validate centos71908ami.json  # First, confirm template is good
packer build centos71908ami.json     # Build CentOS 7 AMI
```
