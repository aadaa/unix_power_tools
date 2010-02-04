#!/usr/bin/ruby
############################################################
# gef - get_field: Gets supplied fields
############################################################
#
# Usage: 
#   Suppose you have a file named DATA
#
#   DATA:
#   ---------------------------------------
#   ABCDE 12345 MMMMM
#   FGHIJ 67890 NNNNN
#
#   You RUN:
#
#   gef 1 3 < DATA
#   ---------------------------------------
#   ABCDE MMMMM
#   FGHIJ NNNNN
#
#
#   gef 1.3 2.2.2 3 < DATA
#   ---------------------------------------
#   CDE 23 MMMMM
#   HIJ 78 NNNNN
#
#   
#   gef NF/1 1.1.2 < DATA
#   ---------------------------------------
#   MMMMM 12345 ABCDE AB
#   NNNNN 67890 FGHIJ FG
#
#   
# Note:
#   Slow on very large amount of text
#
#############################################################
# Author:  BATTUR Sanchin   batturjapan@gmail.com
# Date :   2009/04/26
# License: MIT
#############################################################

text = $stdin.read()

fields = ARGV
raise "gef <field.no> <file>" if fields.size < 1
line_num = 0

text.each { |line|
 
  # line_num is useful when we trace error
  line_num += 1
  out = ''

  # 'words' holds words in the current line
  words = line.split(' ')
  fields.each { |field|

    # let NF be the last field position, like awk
    field = field.gsub('NF', "#{words.size}")
    # also position 0
    word = (field.to_i == 0 ? words.join(' ') : words[field.to_i - 1]) 

    if field.match(/\./)

      items = field.split('.')
      if items.size == 2
        word = word[(items[1].to_i - 1)..(word.size - 1)] 
      elsif items.size == 3
        word = word[(items[1].to_i - 1), items[2].to_i]
      end
    
    elsif field.match(/\//)

      items = field.split('/')
      # need to fit ruby lang spec :(
      if items[0].to_i > items[1].to_i
        reverse = true
        items.reverse!
      end
      # fail soon and noisily as ESR said ;)
      raise "IndexError: #{line_num}" if items[0].to_i > words.size || items[1].to_i > words.size
      arr = words[(items[0].to_i - 1)..(items[1].to_i - 1)]
      arr.reverse! if reverse
      word = arr.join(' ')

    end
    # fail soon and noisily as ESR said ;)
    raise "IndexError: #{line_num}" if word == nil || word.size == 0

    out << " " << word

  }
  puts out.strip
}
