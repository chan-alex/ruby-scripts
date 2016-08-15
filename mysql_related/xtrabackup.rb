#!/usr/bin/ruby

# This is a quick xtrabackup script that I had hacked up.

NUM_KEPT_BACKUPS=2
BACKUP_DIR="/extra_storage/local_backups/xtrabackup"

#Do the xtrabackup
backup_dir_now=File.join(BACKUP_DIR,"xtrabackup_#{Time.now.strftime("%Y%m%d_%H%Mhrs")}")
xtrabackup_cmd="/usr/bin/innobackupex --user=xxxxxxxx --password=xxxxxxx  --compress  #{BACKUP_DIR}"
puts xtrabackup_cmd

`#{xtrabackup_cmd}`


#Purge backups
backup_directories=Dir.entries(BACKUP_DIR).select {|entry| File.directory? File.join(BACKUP_DIR,entry) and !(entry =='.' || entry == '..') }

if backup_directories.length > NUM_KEPT_BACKUPS

  backup_directories.sort!{|x,y| y <=> x }   # descending sort
  dir_to_delete = backup_directories[NUM_KEPT_BACKUPS, backup_directories.length]
  
  dir_to_delete.each { |d|
    puts "deleting #{File.join(BACKUP_DIR,d)}"
    system "/bin/rm -rf #{File.join(BACKUP_DIR,d)}"
  }

end
