if Facter.value(:kernel) == 'Linux'
  mounts = []

  devices = []

  exclude = %w(afs anon_inodefs aufs autofs bdev bind binfmt_.* cgroup cifs
               coda cpuset debugfs devfs devpts ecryptfs fd ftpfs fuse.* gvfs.*
               hugetlbfs inotifyfs iso9660 lustre.* mfs mqueue ncpfs NFS nfs.*
               none pipefs proc ramfs rootfs rpc_.* securityfs shfs shm smbfs
               sockfs sysfs tmpfs udev udf unionfs usbfs pstore efivarfs configfs) 

  exclude = Regexp.union(*exclude.collect { |i| Regexp.new(i) })

  known_devices = Dir['/dev/*'].inject({}) do |k,v|
    if File.exists?(v) and File.blockdev?(v)
      # Resolve any symbolic links we may encounter ...
      v = File.readlink(v) if File.symlink?(v)

      #
      # Make sure that we have full path to the entry under "/dev" ...
      # This tends to be often broken there ...  Relative path hell ...
      #
      v = File.join('/dev', v) unless File.exists?(v)
      k.update(File.stat(v).rdev => v)
    end

    k # Yield hash back into the block ...
  end

  #
  # We utilise rely on "cat" for reading values from entries under "/proc".
  # This is due to some problems with IO#read in Ruby and reading content of
  # the "proc" file system that was reported more than once in the past ...
  #
  Facter::Util::Resolution.exec('cat /proc/mounts 2> /dev/null').each_line do |line|
    # Remove bloat ...
    line.strip!

    # Line of interest should not start with ...
    next if line.empty? or line.match(/^none/)

    # We have something, so let us apply our device type filter ...
    next if line.match(exclude)

    # At this point we split single and valid row into tokens ...
    row = line.split(' ')

    #
    # Only device and mount point are of interest ...
    #
    # When tere are any spaces in the mount point name then Kernel will
    # replace them with as octal "\040" (which is 32 decimal).  We have
    # to accommodate for this and convert them back into proper spaces ...
    #
    # An example of such case:
    #
    #   /dev/sda1 /srv/shares/My\040Files ext3 rw,relatime,errors=continue,data=ordered 0 0
    #
    device = row[0].strip.gsub('\\040', ' ')
    mount  = row[1].strip.gsub('\\040', ' ')

    #
    # Correlate mount point with a real device that exists in the system.
    # This is to take care about entries like "rootfs" under "/proc/mounts".
    #
    device = known_devices.values_at(File.stat(mount).dev).shift || device

    # Add where appropriate ...
    devices << device
    mounts  << mount
  end

  Facter.add('devices') do
    confine :kernel => :linux
    setcode { devices.sort.uniq.join(',') }
  end

  Facter.add('mounts') do
    confine :kernel => :linux
    setcode { mounts.uniq.join(',') }
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
