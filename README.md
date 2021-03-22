# Temper

## Description

Build and configure AMIs from a base AMI.

## Testing Standards

The testing framework used to verify the instance is Inspec. The generated
configuration verifies the operation system against the Center for Internet
Security (CIS) Distribution Independent Linux (DIL) Guidelines using the Inspec
profile in github.com/dev-sec/cis-dil-benchmark as well as against the Ansible
roles applied to the instance.

For the CIS Profile, several controls are skipped as "won't implement" because
they require changes that we cannot make. However, the build should pass for
existing controls without modification on AWS. Testing locally may not (and may
never) pass because of differences between Amazon Linux and CentOS.

## Development

### Prerequisites

1. Vagrant
2. Ruby
3. Python
4. Packer

#### Additional Prerequisites (VM-based development)

1. VirtualBox
2. Centos/6 Vagrant box (local testing)

### Vagrant + VirtualBox

With Homebrew installed:

```Shell
# Install Virtualbox + Vagrant, if not installed. This will work if you have
# Homebrew installed.
$ brew cask install virtualbox virtualbox-extension-pack vagrant
```

### Development Dependencies


```Shell
# Install CentOS 6 image and Test Kitchen deps with Make
$ make develop

# OR

# Run these commands:
$ vagrant box add centos/6
$ bundle install --standalone
```

### Running tests (local)

You can do development locally on your machine with VirtualBox/Vagrant
installed using the CentOS 6 Vagrant box. It's not a perfect match with Amazon
Linux, but it can help with a lot of initial testing.

```Shell
# Run Test Kitchen to install and verify Ansible + Inspec
$ make test
# Validate the Packer template using the Packer validator
$ make validate
```

### Running tests (AWS)

If you would like to test against a real image, you can run your playbook and
tests on EC2 servers by using the `.kitchen.aws.yml` file.

#### CAVEATS

## Don't leave instances running

1. **Running tests on AWS creates real instances that cost money. You must
   delete your instances when complete or they will continue to incur charges.**
   Make sure to run the cleanup afterwards: `make clean` to remove instances
   that were launched for tests.
2. Because you're launching real instances within AWS, **you must have the
   correct permissions to launch instances**.
3. You **must be on the private network** in order to run Test Kitchen, unless
   configure your instances to have public IPs, which requires additional
   configuration changes to Test Kitchen and Packer. Because only the private IP
   is exposed, you won't be able to reach the instance and run tests otherwise.

```Shell
# Run Test Kitchen on AWS
$ export AWS_PROFILE={YOUR PROFILE}
$ make test-aws
```

You can skip the Makefile by running:

```Shell
$ make develop
$ export AWS_PROFILE={YOUR PROFILE}
$ export KITCHEN_LOCAL_YAML=.kitchen.aws.yml
# Make sure to --destroy=always or failing instances will not be terminated and
# potentially incur unnecessary charges.
$ bundle exec kitchen test --destroy=always
```
