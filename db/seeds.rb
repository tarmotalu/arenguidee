instance = Instance.new
instance.name = "Your Instance"
instance.description = "Your Instance"
instance.domain_name = "yourdomain.com"
instance.layout = "application"
instance.admin_name = "Your Admin Name"
instance.admin_email = "admin@yourdomain.com"
instance.email = "admin@yourdomain.com"
instance.save(:validation=>false)

sub_instance = SubInstance.new
sub_instance.short_name = "default"
sub_instance.name = "Your Default Sub Instance"
sub_instance.save(:validation=>false)

ColorScheme.new.save

Category.find_or_create_by_name("Majandus")
Category.find_or_create_by_name("Rahandus")
Category.find_or_create_by_name("Tehnoloogia")
Category.find_or_create_by_name("Välispoliitika")
Category.find_or_create_by_name("Teadus")
Category.find_or_create_by_name("Riigikaitse")
Category.find_or_create_by_name("Ühiskond")
Category.find_or_create_by_name("Sport")
Category.find_or_create_by_name("Õigusteadus")
Category.find_or_create_by_name("Põllumajandus")
Category.find_or_create_by_name("Meelelahutus")
Category.find_or_create_by_name("Kultuur")
Category.find_or_create_by_name("Haridus")
Category.find_or_create_by_name("Keskkond")
