class minecraft::service {
  include supervisor

  supervisor::app {'minecraft':
    command   => $minecraft::exec,
    user      => $minecraft::user,
    directory => $minecraft::homedir,
    subscribe => Class['Minecraft'],
  }

  require minecraft
}
