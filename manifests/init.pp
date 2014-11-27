# Class: minecraft
#
# This class installs and configures a Minecraft server
#
# Parameters:
# - $user: The user account for the Minecraft service
# - $group: The user group for the Minecraft service
# - $homedir: The directory in which Minecraft stores its data
# - $manage_java: Should this module manage the `java` package?
# - $manage_screen: Should this module manage the `screen` package?
# - $manage_curl: Should this module manage the `curl` package?
# - $heap_size: The maximum Java heap size for the Minecraft service in megabytes
# - $heap_start: The initial Java heap size for the Minecraft service in megabytes
#
# Sample Usage:
#
#  class { 'minecraft':
#    user      => 'mcserver',
#    group     => 'mcserver',
#    heap_size => 4096,
#  }
#
class minecraft (
  $user        = 'minecraft',
  $group       = 'minecraft',
  $homedir     = '/opt/minecraft',
  $version     = '1.8.1',
  $manage_java = true,
  $heap_size   = 2048,
  $heap_start  = 512,
)
{
  $url = "https://s3.amazonaws.com/Minecraft.Download/versions/${version}/minecraft_server.${version}.jar"
  $jar_file = "${homedir}/minecraft.jar"
  $exec = "java -Xmx${heap_size}M -Xms${heap_start}M -jar ${jar_file} nogui"
  ensure_packages(['wget'])

  class { 'java':
    distribution => 'jre',
  }

  group { $group:
    ensure => present,
  }

  user { $user:
    gid        => $group,
    home       => $homedir,
    managehome => true,
  }

  exec {'download minecraft jar':
    command => "/usr/bin/wget ${url} -O ${jar_file}",
    user    => $user,
    creates => $jar_file,
    require => [User[$user], Package['wget']],
  }

  file { "${homedir}/ops.txt":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0664',
  } -> Minecraft::Op<| |>

  file { "${homedir}/banned-players.txt":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0664',
  } -> Minecraft::Ban<| |>

  file { "${homedir}/banned-ips.txt":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0664',
  } -> Minecraft::Ipban<| |>

  file { "${homedir}/white-list.txt":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0664',
  } -> Minecraft::Whitelist<| |>

  include minecraft::service

  firewall {'050 enable minecraft server to be reachable':
    provider => iptables,
    port     => 25565,
    proto    => tcp,
    action   => accept,
  }

}
