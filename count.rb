class CountYm
  def initialize(frames_per_sec, time_min, trial_num, result_dir)
    # initialize params
    @frames_per_sec = frames_per_sec
    @time_min = time_min
    @frame_num = time_min * 60 * frames_per_sec
    @trial_num = trial_num

    @result_dir = result_dir
  end

  def write_mouse_name(result_file_name, mouse)
    File.open("#{@result_dir}#{result_file_name}", 'a') { |result_file| result_file.write("#{mouse.chop},") }
  end

  def write_comma_time_min(result_file_name, trial)
    File.open("#{@result_dir}#{result_file_name}", 'a') { |result_file| (@time_min + 1).times { result_file.write(",") } }
  end

  def write_count_center_sum_sec(result_file_name, count_center_sum_sec)
    count_center_sum_sec = count_center_sum_sec.map { |count| count.to_s.gsub(/\.0$/, '') }
    File.open("#{@result_dir}#{result_file_name}", 'a') { |result_file| result_file.write("#{count_center_sum_sec.join(',')}\n") }
  end

  def count(read_file_name, result_file_name, mouse, trial, count_center_sum_sec)
    # initialize
    count_center = Array.new(@frame_num) { 0.0 }
    count_center_per_min = Array.new(@time_min) { 0.0 }
    count_error = 0
    error_flag = false

    puts "read file : #{read_file_name}"
    File.open("files/#{read_file_name}") do |read_file|
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

          break if frame > @frame_num
          count_error += 1
        elsif line =~ /^\s+(\d+)\s+(\d+)\s+(\d+).*D/
          # only D
          puts "only D"
          frame, x, y = [$1.to_i, $2.to_f, $3.to_f]
          p "frame : #{frame}"
          p "x : #{x}"
          p "y : #{y}"

          break if frame > @frame_num
          unless x < (width * Rational(1,4)).to_f || x > (width * Rational(3,4)).to_f || y < (height * Rational(1,4)).to_f || y > (height * Rational(3,4)).to_f
            p "center!"
            count_center[frame - 1] += 0.5
            1.upto(@time_min) do |min|
              if frame <= (@frames_per_sec * 60 * min)
                count_center_per_min[min - 1] += 0.5
                break
              end
            end
          end
        else
          # other
          puts "other"
        end
      end
    end

    p count_center

    # TODO replace 0.5 if count over 0.5
    raise if count_center.any? { |count| count > 0.5 }
    count_center_sum_sec[trial] += count_center.inject(:+)

    # remove .0
    count_center_per_min = count_center_per_min.map { |count| count.to_s.gsub(/\.0$/, '') }

    p "count_center_sum_sec[#{trial}] = #{count_center_sum_sec[trial]}"

    File.open("#{@result_dir}#{result_file_name}", 'a') { |result_file| result_file.write("#{count_center_per_min.join(',')},,") }
  end
end

frames_per_sec = 2
time_min = 4
trial_num = 5
result_dir = "#{File.expand_path(File.dirname(__FILE__))}/result/"

count_ym = CountYm.new(frames_per_sec, time_min, trial_num, result_dir)

files_dir = "#{File.expand_path(File.dirname(__FILE__))}/files/"

result_file_empty_name = "result-#{Time.now.strftime('%Y%m%d-%H%M%S')}-E.txt"
result_file_stim_name = "result-#{Time.now.strftime('%Y%m%d-%H%M%S')}-S.txt"

file_names = Dir.entries(files_dir).delete_if { |file_name| file_name =~ /^\./}
mouses = file_names.map { |file_name| file_name.gsub(/\w{2}.txt$/, "") }.uniq

alphabets = ("a".."z").to_a

mouses.each do |mouse|

  ##### Empty #####
  result_file_name = result_file_empty_name
  count_ym.write_mouse_name(result_file_name, mouse)

  count_center_sum_sec = Array.new(trial_num) { 0.0 }

  # write result of trial
  trial_num.times do |trial|
    if file_names.include?("#{mouse}#{alphabets[trial]}1.txt")
      read_file_name = "#{mouse}#{alphabets[trial]}1.txt"
    elsif file_names.include?("#{mouse}#{alphabets[trial]}E.txt")
      read_file_name = "#{mouse}#{alphabets[trial]}E.txt"
    elsif file_names.include?("#{mouse}#{alphabets[trial]}e.txt")
      read_file_name = "#{mouse}#{alphabets[trial]}e.txt"
    else
      count_ym.write_comma_time_min(result_file_name, trial)
      count_center_sum_sec[trial] = ''
      next
    end

    count_ym.count(read_file_name, result_file_name, mouse, trial, count_center_sum_sec)
  end

  count_ym.write_count_center_sum_sec(result_file_name, count_center_sum_sec)

  ##### Stim #####
  result_file_name = result_file_stim_name
  count_ym.write_mouse_name(result_file_name, mouse)

  count_center_sum_sec = Array.new(trial_num) { 0.0 }

  # write result of trial
  trial_num.times do |trial|
    if file_names.include?("#{mouse}#{alphabets[trial]}2.txt")
      read_file_name = "#{mouse}#{alphabets[trial]}2.txt"
    elsif file_names.include?("#{mouse}#{alphabets[trial]}S.txt")
      read_file_name = "#{mouse}#{alphabets[trial]}S.txt"
    elsif file_names.include?("#{mouse}#{alphabets[trial]}s.txt")
      read_file_name = "#{mouse}#{alphabets[trial]}s.txt"
    else
      count_ym.write_comma_time_min(result_file_name, trial)
      count_center_sum_sec[trial] = ''
      next
    end

    count_ym.count(read_file_name, result_file_name, mouse, trial, count_center_sum_sec)
  end

  count_ym.write_count_center_sum_sec(result_file_name, count_center_sum_sec)
end