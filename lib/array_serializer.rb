class ArraySerializer
  def load(str)
    if str
      str.delete("'").split(';')
    else
      []
    end
  end

  def dump(arr)
    arr.reject{ |c| c.blank? }.map{|item| "'"+item.to_s+"'"}.join(';')
  end
end