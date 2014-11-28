define minecraft::plugin($plugin_name=$title, $source, ensure=present) {
  $destination = "${minecraft::homedir}/plugins/${plugin_name}.jar",
  if ($ensure == 'present') {
    exec { "fetch ${plugin_name}":
      command     => '$source',
      destination => $destination,
      user        => $minecraft::user,
      notify      => Service['minecraft'],
    }
  } else {
    file{$destination:
      ensure => purged,
    }
  }

  require minecraft
}
