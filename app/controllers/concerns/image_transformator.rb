# frozen_string_literal: true
require 'net/http/post/multipart'
module ImageTransformator
  def transform(image, answers)
    test=JSON.parse(File.read(answers).force_encoding('UTF-8'))
    max_letter=test["max_letter"]
    prediction = Hash.new {|h,k| h[k] = [] }
    (0..14).each do |i|
      temp_image = MiniMagick::Image.open(image)
      row = temp_image.crop "818x71+482+#{466 + 71 * i}"
      row.write "row#{i}.jpg"

      (0..7).each do |j|
        row = MiniMagick::Image.open("row#{i}.jpg")
        row.crop "102x71+#{102 * j}+0"
        arr = row.get_pixels.flatten(1)
        whites = arr.filter { |pixel| pixel[0] >= 245 && pixel[1] >= 245 && pixel[2] >= 245 }.length
        whites_percent = whites.to_f / arr.length
        if whites_percent < 0.89
          img_path = "output_#{i + 1}_#{j + 1}.jpg"
          row.write img_path
          `convert -respect-parenthesis \\( output_#{i + 1}_#{j + 1}.jpg -colorspace gray -type grayscale -contrast-stretch 0 \\) \\( -clone 0 -colorspace gray -negate -lat 15x15+5% -contrast-stretch 0 \\) -compose copy_opacity -composite -fill "white" -opaque none +matte -deskew 40%  -auto-orient -sharpen 0x1 output_#{i + 1}_#{j + 1}.jpg`
          prediction[(i+1).to_s]<<(get_letter(img_path, max_letter)["letter"])
        end
      end
    end
    (0..14).each do |i|
      temp_image = MiniMagick::Image.open(image)
      row = temp_image.crop "818x71+1512+#{466 + 71 * i}"
      row.write "row#{i + 15}.jpg"

      (0..7).each do |j|
        row = MiniMagick::Image.open("row#{i + 15}.jpg")
        row.crop "102x71+#{102 * j}+0"
        arr = row.get_pixels.flatten(1)
        whites = arr.filter { |pixel| pixel[0] >= 245 && pixel[1] >= 245 && pixel[2] >= 245 }.length
        whites_percent = whites.to_f / arr.length
        if whites_percent < 0.89
          img_path = "output_#{i + 16}_#{j + 1}.jpg"
          row.write img_path
          `convert -respect-parenthesis \\( output_#{i + 16}_#{j + 1}.jpg -colorspace gray -type grayscale -contrast-stretch 0 \\) \\( -clone 0 -colorspace gray -negate -lat 15x15+5% -contrast-stretch 0 \\) -compose copy_opacity -composite -fill "white" -opaque none +matte -deskew 40%  -auto-orient -sharpen 0x1 output_#{i + 16}_#{j + 1}.jpg`
          prediction[(i+16).to_s]<<(get_letter(img_path, max_letter)["letter"])
        end
      end
    end
    `rm -f row*`
    `rm -f output*`
    return prediction
  end

  def get_letter(img_path, max_letter)
    url = URI.parse(ENV['API_URL'])
    File.open(img_path) do |jpg|
      req = Net::HTTP::Post::Multipart.new(URI(ENV['API_URL']), {'photo': UploadIO.new(jpg, "image/jpeg", "image.jpg")})
      max_prob = Net::HTTP.start(url.host, url.port) do |http|
        res = http.request(req)
        probs = JSON.parse(res.body)
        #probs[6]["prob"]=probs[6]["prob"].to_f+probs[7]["prob"].to_f #Е+Ё
        #probs[10]["prob"]=probs[10]["prob"].to_f+probs[11]["prob"].to_f #И+Й
        probs=probs.filter{|el| el["letter"]<=max_letter}
        return probs.max{|a, b| a["prob"].to_f() <=> b["prob"].to_f()}
      end
    end
  end
end
