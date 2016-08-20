#!/usr/bin/ruby

# A quickly hacked script to download color pictures of earth from the 
# himawari satellite.


DOWNLOAD_DIR = "/Users/Shared/satellite_images/"
COLOUR_IMAGE_prefix = "http://www.jma.go.jp/en/gms/imgs_c/6/visible/1/" 

def add0_if_1(str)

  str.length == 1 ? "0" + str : str 

end


utc_time = Time.new - (60 * 60 * 8)
utc_month = add0_if_1(utc_time.month.to_s)
utc_day   = add0_if_1(utc_time.day.to_s)
utc_hour  = add0_if_1(utc_time.hour.to_s)

date_time = utc_time.year.to_s + utc_month + utc_day + utc_hour + "00"
url = COLOUR_IMAGE_prefix + date_time + "-00.png"
puts url


`/usr/bin/curl #{url} > #{DOWNLOAD_DIR}himawari_image.png`

