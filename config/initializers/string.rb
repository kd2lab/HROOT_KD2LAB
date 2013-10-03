
# useful string extensions
class String
  def mreplace(hash)
    text = self.dup
    if hash
      hash.each do |k,v| text.gsub!(k.to_s,v.to_s) end
    end
    text
  end
end