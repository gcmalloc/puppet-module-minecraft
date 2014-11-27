class minecraft::service {
  include supervisor

  supervisor::app {'minecraft':
    command   => $minecraft::exec,
    user      => $minecraft::user,
    directory => $rtmp_server::home,
    subscribe => Class['Minecraft'],
  }

  require minecraft
}
