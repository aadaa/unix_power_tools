#!/usr/bin/ruby
txt_usage = "Usage: dbci.rb <full_path_of_sqlite_db> -table:{<table_name_in_db>=<full_path_of_textfile>,*args} [-int:{<column_name>,*args} [-append:<boolean>]]"
txt_info = <<TEXT
#*******************************************************************************
# NAME  
#        dbci.rb - creates sqlite database, and inserts record from text files
#
# SYNOPSIS
#        #{txt_usage}
#        
#       
# DESCRIPTION
#        There are times calculating deep logical data with awk(sed, joins) is 
#        much time consuming or later some aspects of them gradually 
#        becomes maintainence nightmare. What if we could write custom SQL
#        commands, and execute them over those plain text files?
#
#        In some case, writing SQL is much more easier and quicker. This little
#        tool helps CGI programmers to import plain text file into sqlite database
#        as a structured table. Means, it enables a programmer to concentrate on the
#        the program logic rather than typing & asserting various IO operations.
#
#        First row of the text file will be considered as column names.
#        Every column in each row must have some data(not space).
#        Plain file example below:
#
#        Line.No | employee file data
#        -----------------------------
#           001. | id name sex age
#           002. | AA Battur male 26
#           003. | BB George male 45
#           004. | CC Sarah female 30
#
#
#        -table:{<table_name_in_db>=<full_path_of_textfile>,*args}
#               Provide table names and the full path of your text files.
#
#        -int:{<column_name>,*args} 
#               Name numeric columns here. Later it's easier to sort & filter.
#               This parameter is optional.
#
#        -append:<boolean>
#               Supply 'true' or 'false' here. If you put 'true' records will
#               be appended into existing table.
#               This parameter is optional.
#
#
#         Note: This tool is intended for CGI programmers doing lot of text
#         based operation. Therefore may not fit for every case on earth ;)
#
#
# EXAMPLE
#        dbci.rb company.db -table:{positions=/abc_company/position,employees=/abc_company/employees/} -int:{age,salary} -append:true
#        Note: Do not put space between sub options!
#
#
# AUTHOR
#        Battur Sanchin
#
#                  {
#                    :homepage => 'http://battur.blogspot.com',
#                    :email    => 'batturjapan@gmail.com',
#                    :flickr   => 'http://flickr.com/photos/battur'
#                  }
#
# COPYRIGHT
#        Copyright © 2009 Battur Sanchin. Licence: MIT License
#
# SEE ALSO       
#        SQLite homepage: http://www.sqlite.org
#
#
TEXT

tmp = "/tmp/tmp#{$$}"


def err
  puts "Non applicable arguments. Type 'dbci.rb -help' for usage tips."
  exit 1
end


db = ARGV[0]
err unless ARGV.shift 

if db.eql? '-help' then
  puts txt_info.gsub(/^\# ?(\*+)?/,'')
  exit 0
end


Table = Struct.new(:name, :txtfile)
tables, integers, append = [], [], false


# load supplied options here
ARGV.each do |a|
  key, val = a.split(':')[0], a.split(':')[1].gsub(/\{|\}/,'')

  if key.eql? '-table'

    params = val.split('=')
    err if params.size < 2
    tables << Table.new(params[0], params[1])

  elsif key.eql? '-int'
    integers << val
  elsif key.eql? '-append'
    append = (val.eql? 'true') ? true : false
  elsif key.match(/^[^-]+/)
    puts "Option '#{key}' should start with '-' sign."
    puts txt_usage
    err
  end

end



# iterate over tables
tables.each do |table|

  # fetch column names
  header = `head -1 #{table.txtfile}`
  col_defs, columns  = [], header.split

  # create SQL statement, define data type
  columns.each do |col|
    col_defs << "#{col} #{integers.include? col ? 'INTEGER' : 'TEXT'}"
  end
  create_stmt = "CREATE TABLE #{table.name} (" << col_defs.join(', ') << ");"

  
  # we need data without header to import into db
  datafile = "#{tmp}-data"
  `sed '1d' #{table.txtfile} > #{datafile}`

  File.open("#{tmp}-insert_stmt", "w") do |file|
    file.puts '.separator " "'
    file.puts ".import #{datafile} #{table.name}"
  end


  # execute SQL statements
  `sqlite3 #{db} "DROP TABLE IF EXISTS #{table.name};"` unless append == true
  `sqlite3 #{db} "#{create_stmt}"`
  `sqlite3 #{db} < "#{tmp}-insert_stmt"`


  # remove temporary files
  `rm #{tmp}-*`

end

# that's the end ;)
exit 0


