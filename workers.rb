Dir['./workers/*'].each do |path|
  require path
end

