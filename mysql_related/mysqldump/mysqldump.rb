#!/usr/bin/ruby


# A ruby wrapper the mysqldump command for making backups.
# Example usage:
#   mysqldump.rb --db operations --prefix "SG" --opts "--single-transaction  --hex-blob --complete-insert --triggers --routines --events --dump-slave=2 "

require 'optparse'
require 'syslog'
require 'date'
require 'open3'

class Mylogger 
  def initialize()
    @syslog = Syslog.open("mysqldump.rb")
  end

  def log(msg)
    puts msg
    @syslog.info(msg)
  end

  def run_cmd_with_logging(cmd)

      log("Attempting to execute: #{cmd}")
      
      Open3.popen3(cmd) { |stdin, stdout, stderr, wait_thr| 
        exit_status = wait_thr.value

        if exit_status.exitstatus != 0
          log("The command exited with non-zero status.")
          log("The error code was #{exit_status.exitstatus}")
          log("The error output was: \n")
          log("#{stderr.read}")
          log("Aborting script. ")
          exit(1)
        end
      }
      
      log("The command was executed successfully.")
  end   
end


options = {:backup_dest => '/backups/mysql/mysqldump', :keep_days => 30, :defaults_file => '/root/.my.cnf', :prefix =>'',
           :mysqldump_opts => "--opt --single-transaction --hex-blob --complete-insert --triggers --routines --events --set-gtid-purged=OFF  --dump-slave=2" }
opts= OptionParser.new 
opts.banner = 'Usage: mysqldump.rb  --database database_name --backup-dest directory --keep-days 30'
opts.on("--db", "--database DATABASE", String)  {|value| options[:database]=value}
opts.on("--keep_days DAYS", Integer)            {|value| options[:keep_days]=value}
opts.on("--backup_dest DIR", String)            {|value| options[:backup_dest]=value}
opts.on("--defaults-file FILE", String)         {|value| options[:default_file]=value}
opts.on("--prefix PREFIX", String)              {|value| options[:prefix]=value}
opts.on("--opts OPTS", String)        {|value| options[:mysqldump_opts]=value}

begin
  opts.parse!
  mandatory = [:database]                                         
  missing = mandatory.select{ |param| options[param].nil? }      
  unless missing.empty?                                            
    puts "Missing options: #{missing.join(', ')}"                  
    puts opts
    exit                                                           
  end                                                             
rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
  puts $!.to_s                                                           
  puts optparse                                                          
  exit                                                                
end  

#Backup section starts here.
logger = Mylogger.new

unless File.directory?(options[:backup_dest]) 
  logger.log("The specified backup directory, #{options[:backup_dest]}, does not exist. Exiting.")
  exit 1
end


today = Date.today.to_s

mysqldump_file = options[:prefix] + '_' + options[:database] + '_' + today + ".sql"
mysqldump_file = File.join(options[:backup_dest], mysqldump_file)
cmd="/usr/bin/mysqldump --defaults-file=#{options[:defaults_file]} #{options[:mysqldump_opts]}  #{options[:database]} > #{mysqldump_file}"
logger.run_cmd_with_logging(cmd)


#Save the database definitions for reference.
schema_file = options[:prefix] + '_' + options[:database] + '_schema_' + today + ".sql"
schema_file = File.join(options[:backup_dest], schema_file)
cmd="/usr/bin/mysqldump --defaults-file=#{options[:defaults_file]}  --no-data --routines  --triggers --events  #{options[:database]} > #{schema_file}"
logger.run_cmd_with_logging(cmd)


#Purge old backups.
purge_cmd="/usr/bin/find #{options[:backup_dest]} -mtime +#{options[:keep_days]} -exec /bin/rm -f {} \\;"
logger.run_cmd_with_logging(purge_cmd)


exit(0)
