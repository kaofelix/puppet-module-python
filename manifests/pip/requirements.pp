# Installs packages in a requirements file for a virtualenv.
# Pip tries to upgrade packages when the requirements file changes.
define python::pip::requirements($venv, $owner=undef, $group=undef) {
  $requirements = $name
  $checksum = "$venv/requirements.checksum"

  Exec {
    user => $owner,
    group => $group,
    cwd => "/tmp",
  }

  file { $requirements:
    ensure => present,
    replace => false,
    owner => $owner,
    group => $group,
    content => "# Puppet will install packages listed here and update them if
# the the contents of this file changes.",
  }

  # We create a sha1 checksum of the requirements file so that
  # we can detect when it changes:
  exec { "create new checksum of $name requirements":
    command => "sha1sum $requirements > $checksum",
    require => File[$requirements],
    refreshonly => true,
  }

  exec { "update $name requirements":
    command => "$venv/bin/pip install -Ur $requirements",
    cwd => $venv,
    timeout => 0, # sometimes, this can take a while
    require => File[$requirements],
    unless => "sha1sum -c $checksum",
    notify => Exec["create new checksum of $name requirements"],
    logoutput => "on_failure",
  }
}
