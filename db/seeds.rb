instance = Instance.new
instance.name = "Your Instance"
instance.description = "Your Instance"
instance.domain_name = "yourdomain.com"
instance.layout = "application"
instance.admin_name = "Your Admin Name"
instance.admin_email = "admin@yourdomain.com"
instance.email = "admin@yourdomain.com"
instance.save(:validation=>false)

ColorScheme.new.save

sub_instance = SubInstance.new
sub_instance.short_name = "default"
sub_instance.name = "Your Default Sub Instance"
sub_instance.save(:validation=>false)
