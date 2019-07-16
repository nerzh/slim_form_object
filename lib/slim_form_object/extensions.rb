class Array

  def iterate_with_each_pair
    cloned_objects = Array.new(self)
    while object_1 = cloned_objects.delete(cloned_objects[0])
      cloned_objects.each do |object_2|
        yield(object_1, object_2)
      end
    end
  end
end