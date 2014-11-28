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
#    user          => 'mcserver',
#    group         => 'mcserver',
#    heap_size     => 4096,
#    eula_accepted => true,
#  }
#
class minecraft (
  $user          = 'minecraft',
  $group         = 'minecraft',
  $homedir       = '/opt/minecraft',
  $version       = undef,
  $manage_java   = true,
  $heap_size     = 2048,
  $heap_start    = 512,
  $eula_accepted = true,
  $use_bukkit    = false,
)
{
  if ($version) {
    $real_version = $version
  } else {
    $real_version = $use_bukkit ? {
      true => '02388_1.6.4-R2.0',
      false => '1.8.1',
    }
  }

  $url = $use_bukkit ? {
    true => "https://dl.bukkit.org/downloads/bukkit/get/${real_version}/bukkit.jar",
    false => "https://s3.amazonaws.com/Minecraft.Download/versions/${real_version}/minecraft_server.${real_version}.jar",
  }
  $jar_file = "${homedir}/minecraft${real_version}.jar"
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

  exec {"download minecraft jar version ${real_version}":
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


  file {"${homedir}/eula.txt":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0664',
    content => "eula=${eula_accepted}\n"
  }

  file {"${homedir}/plugins":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0664',
  }

  include minecraft::service

  firewall {'050 enable minecraft server to be reachable':
    provider => iptables,
    port     => 25565,
    proto    => tcp,
    action   => accept,
  }

}
