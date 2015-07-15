# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>
#
# Modified to work with SmartOS
# by Braxton Huggins <braxton@delorum.com>

module VagrantPlugins
  module GuestSmartos
    module Cap
      class MountVirtualBoxSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          # ensure that the vboxfs mount helper is in the right place
          machine.communicate.execute("if [ ! -d /etc/fs/vboxfs ]; then #{machine.config.smartos.suexec_cmd} mkdir -p /etc/fs/vboxfs; fi")
          machine.communicate.execute("if [ ! -L /etc/fs/vboxfs/mount ]; then #{machine.config.smartos.suexec_cmd} ln -s ../../../sbin/vboxfsmount /etc/fs/vboxfs/mount; fi")
          # These are just far easier to use than the full options syntax
          owner = options[:owner]
          group = options[:group]

          # Create the shared folder
          machine.communicate.execute("#{machine.config.smartos.suexec_cmd} mkdir -p #{guestpath}")

          if owner.is_a? Integer
            mount_uid = owner
          else
            # We have to use this `id` command instead of `/usr/bin/id` since this
            # one accepts the "-u" and "-g" flags.
            mount_uid = "`/usr/xpg4/bin/id -u #{owner}`"
          end

          if group.is_a? Integer
            mount_gid = group
          else
            mount_gid = "`/usr/xpg4/bin/id -g #{group}`"
          end

          # Mount the folder with the proper owner/group
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid}"
          if options[:mount_options]
            mount_options += ",#{options[:mount_options].join(",")}"
          end

          machine.communicate.execute("#{machine.config.smartos.suexec_cmd} /sbin/mount -F vboxfs #{mount_options} #{name} #{guestpath}")

          # chown the folder to the proper owner/group
          machine.communicate.execute("#{machine.config.smartos.suexec_cmd} chown #{mount_uid}:#{mount_gid} #{guestpath}")
        end
      end
    end
  end
end
