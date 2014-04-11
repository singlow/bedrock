#!/bin/bash

# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR=/etc/puppet/

# NB: librarian-puppet might need git installed. If it is not already installed
# in your basebox, this will manually install it at this point using apt or yum

if which git >/dev/null; then
  echo git is installed
else
  apt-get -q -y update
  apt-get -q -y install git build-essential ruby1.9.3
fi

check_version()
{
  local version=$1 check=$2
  local winner=$(echo -e "$version\n$check" | sed '/^$/d' | sort -nr | head -1)
  [[ "$winner" = "$version" ]] && return 0
  return 1
}

if check_version $(ruby -e "print RUBY_VERSION") 1.9.3 >/dev/null; then
  echo ruby is up-to-date
else
  apt-get -q -y update
  apt-get -q -y install ruby1.9.3
fi

if [ ! -d "$PUPPET_DIR" ]; then
  mkdir -p $PUPPET_DIR
fi
cp /vagrant/puppet/Puppetfile $PUPPET_DIR

if [ "$(gem search -i librarian-puppet)" = "false" ]; then
  gem install librarian-puppet
  cd $PUPPET_DIR && librarian-puppet install --clean
else
  cd $PUPPET_DIR && librarian-puppet update
fi
