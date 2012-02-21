filelist = "/home/surma/filelist.txt"
basepath = "/etc"

conffile = File.open(filelist)
conffile.each do |line|
   line.strip!
   puts line unless File.directory?(File.join(basepath, line))
end
