# params
frames_per_sec = 2
time_min = 4
frame_num = time_min * 60 * frames_per_sec

# directories
files_dir = "#{File.expand_path(File.dirname(__FILE__))}/files/"
result_dir = "#{File.expand_path(File.dirname(__FILE__))}/result/"

result_file_name = "result-#{Time.now.strftime('%Y%m%d-%H%M%S')}.txt"

Dir.chdir(files_dir)
Dir::glob("*.txt").each do |read_file_name|
  # initialize
  count_center = Array.new(frame_num) { 0.0 }
  count_error = 0
  error_flag = false

  puts "read file : #{read_file_name}"

  File.open(read_file_name) do |read_file|
    while line = read_file.gets("\r")
      line.chomp!
      p "----------------"
      if line =~ /(\d+)[\s\w]*pixels\(width\)\D*\d+\D*(\d+)[\s\w]*pixels\(hight\)/
        # get width and height
        width, height = [$1.to_i, $2.to_i]
        p "width : #{width}"
        p "height : #{height}"
      elsif line =~ /^\s+(\d+)\s+(\d+)\s+(\d+)\s+.*[DL]\s+[DL]/
        # D and L
        puts "D and L"
        frame, x, y = [$1.to_i, $2.to_f, $3.to_f]
        p "frame : #{frame}"
        p "x : #{x}"
        p "y : #{y}"

        break if frame > frame_num

        count_error += 1
      elsif line =~ /^\s+(\d+)\s+(\d+)\s+(\d+).*D/
        # only D
        puts "only D"
        frame, x, y = [$1.to_i, $2.to_f, $3.to_f]
        p "frame : #{frame}"
        p "x : #{x}"
        p "y : #{y}"

        break if frame > frame_num

        unless x < (width * Rational(1,4)).to_f || x > (width * Rational(3,4)).to_f || y < (height * Rational(1,4)).to_f || y > (height * Rational(3,4)).to_f
          p "center!"
          count_center[frame - 1] += 1.0
        end
      else
        # other
        puts "other"
      end
    end
  end

  p count_center

  # TODO replace 1.0 if count over 1.0
  raise if count_center.any? { |count| count > 1.0 }

  count_center_sum_frame = count_center.inject(:+)
  count_center_sum_sec = count_center_sum_frame / 2.0

  # TODO remove .0

  p "count_center_sum_frame = #{count_center_sum_frame}"
  p "count_center_sum_sec = #{count_center_sum_sec}"

  if read_file_name =~ /1.txt$/
    trial_name = read_file_name.sub(/1.txt$/, 'E')
  elsif read_file_name =~ /2.txt$/
    trial_name = read_file_name.sub(/2.txt$/, 'S')
  else
    trial_name = read_file_name.slice(/\w+/)
  end


  File.open("#{result_dir}#{result_file_name}", 'a').write("#{trial_name} #{count_center_sum_sec} #{count_error}\n")
end
