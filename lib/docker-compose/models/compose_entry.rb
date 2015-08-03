class ComposeEntry
  def initialize(hash_attributes)
    @id = hash_attributes['id']
    @build = hash_attributes['build']
    @image = hash_attributes['image']
    @ports = hash_attributes['ports']
    @volumes = hash_attributes['volumes']
    @links = hash_attributes['links']
  end
end
