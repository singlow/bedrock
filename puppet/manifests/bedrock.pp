package { "nginx":
  ensure => installed
}

service { "nginx":
  require => Package["nginx"],
  ensure => running
}

package { "php5-fpm":
  ensure => installed
}
package { "php5-cli":
  ensure => installed
}
package { "php5-mysql":
  ensure => installed
}
package { "php5-gd":
  ensure => installed
}
package { "php5-mcrypt":
  ensure => installed
}
package { "php5-json":
  ensure => installed
}

service { "php5-fpm":
  require => [
    Package["php5-fpm"],
    Package["php5-mysql"],
    Package["php5-gd"],
    Package["php5-mcrypt"],
    Package["php5-json"]
  ],
  ensure => running
}

file { "/etc/nginx/sites-enabled/default":
  require => Package["nginx"],
  ensure => absent,
  notify => Service["nginx"]
}

$users = {
  'wordpress@localhost' => {
    ensure => 'present',
    password_hash => '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19'
  }
}

$grants = {
  'wordpress@localhost/wordpress.*' => {
    ensure => 'present',
    options => ['GRANT'],
    privileges => ['ALL'],
    table => 'wordpress.*',
    user => 'wordpress@localhost'
  }
}

$databases = {
  'wordpress' => {
    ensure => 'present',
    charset => 'utf8'
  }
}

class { '::mysql::server':
  root_password => 'password',
  users => $users,
  grants => $grants,
  databases => $databases
}

include '::mysql::server'

file { "/etc/nginx/sites-enabled/wordpress":
  require => [
    Package["nginx"],
    Package["php5-fpm"],
  ],
  ensure => "file",
  content =>
    "
    server {
      listen 80 default_server;
      sendfile off;

      server_name ~^([^\\.]+)\\..*\$;
      set \$subdomain \$1;

      access_log off;
      error_log /var/log/nginx/error.log notice;

      root /vagrant/web;
      index index.php index.html;

      location ~ ^/assets/(img|js|css|fonts)/(.*)\$ {
        try_files \$uri \$uri/ /app/themes/roots/assets/\$1/\$2 /app/themes/$subdomain/\$1/\$2;
      }

      location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
      }

      location ~ \\.php {
        include fastcgi_params;
        keepalive_timeout 80;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param  HTTPS off;
        fastcgi_pass	unix:/var/run/php5-fpm.sock;
      }
    }
    ",
  notify => Service['nginx']
}
       
exec { "install_composer":
  command => "curl =sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin",
  path => "/usr/local/bin:/usr/bin:/bin"
}

file { '/usr/local/bin/composer':
  ensure => 'link',
  target => '/usr/local/bin/composer.phar'
}

package { "git": ensure => installed }
package { "vim": ensure => installed }

class { 'nodejs':
  version => 'stable'
}

package { 'grunt-cli':
  provider => npm
}
